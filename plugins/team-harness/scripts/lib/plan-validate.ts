import { readFileSync } from "node:fs";
import { glob } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";

import { parse as parseYaml } from "yaml";

export interface PlanIssue {
  file: string;
  line: number;
  rule: string;
  message: string;
}

export type ValidationProfile = "default" | "template";

export interface PlanValidatorConfig {
  integrationBranch?: string;
  plansGlobs?: string[];
  excludeGlobs?: string[];
  requireRepoDefaultLine?: boolean;
  repoDefaultHint?: string;
}

export interface ValidatePlanOptions {
  profile?: ValidationProfile;
  config?: PlanValidatorConfig;
}

export interface PlanFrontmatter {
  name?: unknown;
  overview?: unknown;
  todos?: unknown;
  isProject?: unknown;
}

export interface PlanTodo {
  id: string;
  content?: string;
  status: string;
}

const ALLOWED_STATUSES = new Set(["pending", "in_progress", "completed", "cancelled"]);

const AUTHORITY_LABELS = [
  "Plan-only PR",
  "Open PR only",
  "Merge granted",
  "Manual verification gate",
] as const;

export type AuthorityLabel = (typeof AUTHORITY_LABELS)[number];

const PLAN_CLOSURE_ID = "plan-closure";

const DEFAULT_PLANS_GLOBS = [".cursor/plans/**/*.plan.md"];
const DEFAULT_EXCLUDE_GLOBS = [
  ".cursor/plans/archive/**",
  "**/_template.plan.md",
  "**/planning-methodology/_template.plan.md",
];

const ELLIPSIS_PLACEHOLDER =
  /^[\s*]*(?:\.{3}|…+|\.…|…\.|\u2026|\*+\s*)+[\s*]*$/u;

export function loadPlanValidatorConfig(repoRoot: string): PlanValidatorConfig | undefined {
  const configPath = join(repoRoot, ".cursor/plan-validator.json");
  try {
    const raw = readFileSync(configPath, "utf8");
    return JSON.parse(raw) as PlanValidatorConfig;
  } catch (err) {
    const code = (err as NodeJS.ErrnoException).code;
    if (code === "ENOENT") {
      return undefined;
    }
    throw err;
  }
}

export function normalizeAuthorityFromPromptLine(line: string): AuthorityLabel | null {
  const trimmed = line.trim();
  for (const label of AUTHORITY_LABELS) {
    if (trimmed.toLowerCase().startsWith(label.toLowerCase())) {
      return label;
    }
  }
  return normalizeAuthority(trimmed);
}

export function normalizeAuthority(raw: string): AuthorityLabel | null {
  const trimmed = raw.trim().replace(/\s+/g, " ");
  const lower = trimmed.toLowerCase();

  for (const label of AUTHORITY_LABELS) {
    if (lower === label.toLowerCase()) {
      return label;
    }
  }

  const planOnlyAliases = [
    "commit the plan and open a pr",
    "commit the plan only",
    "open a plan-only pr",
    "prepare a planning pr",
    "open a pr for plan review",
    "redraft the plan and open the pr",
    "commit only the plan",
    "plan review before implementation",
  ];
  if (planOnlyAliases.some((a) => lower.startsWith(a) || lower.includes(a))) {
    return "Plan-only PR";
  }

  if (lower.startsWith("plan-only")) {
    return "Plan-only PR";
  }
  if (lower.startsWith("open pr only")) {
    return "Open PR only";
  }
  if (lower.startsWith("merge granted")) {
    return "Merge granted";
  }
  if (lower.startsWith("manual verification")) {
    return "Manual verification gate";
  }

  return null;
}

function issue(
  file: string,
  line: number,
  rule: string,
  message: string,
): PlanIssue {
  return { file, line, rule, message };
}

export interface ParsedFrontmatter {
  data: PlanFrontmatter;
  todos: PlanTodo[];
  frontmatterEndLine: number;
}

export function parsePlanFrontmatter(
  content: string,
  file: string,
): { ok: true; parsed: ParsedFrontmatter } | { ok: false; issues: PlanIssue[] } {
  const issues: PlanIssue[] = [];
  if (!content.startsWith("---\n") && !content.startsWith("---\r\n")) {
    issues.push(issue(file, 1, "frontmatter.delimiter", "Plan must start with YAML frontmatter (---)"));
    return { ok: false, issues };
  }

  const endIdx = content.indexOf("\n---\n", 4);
  const endIdxCr = content.indexOf("\n---\r\n", 4);
  let end = -1;
  if (endIdx !== -1 && (endIdxCr === -1 || endIdx < endIdxCr)) {
    end = endIdx;
  } else if (endIdxCr !== -1) {
    end = endIdxCr;
  }

  if (end === -1) {
    issues.push(
      issue(file, 1, "frontmatter.delimiter", "Unclosed YAML frontmatter (missing closing ---)"),
    );
    return { ok: false, issues };
  }

  const yamlText = content.slice(4, end);
  const frontmatterEndLine = content.slice(0, end + 5).split(/\r?\n/).length;

  let data: PlanFrontmatter;
  try {
    data = parseYaml(yamlText) as PlanFrontmatter;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    issues.push(issue(file, 1, "frontmatter.yaml", `Malformed YAML in frontmatter: ${message}`));
    return { ok: false, issues };
  }

  if (!data || typeof data !== "object") {
    issues.push(issue(file, 1, "frontmatter.schema", "Frontmatter must be a YAML mapping"));
    return { ok: false, issues };
  }

  const todosRaw = data.todos;
  if (!Array.isArray(todosRaw) || todosRaw.length === 0) {
    issues.push(issue(file, 1, "frontmatter.todos", "Frontmatter todos must be a non-empty array"));
    return { ok: false, issues };
  }

  const todos: PlanTodo[] = [];
  for (let i = 0; i < todosRaw.length; i++) {
    const item = todosRaw[i];
    if (!item || typeof item !== "object") {
      issues.push(issue(file, 1, "frontmatter.todos", `Todo at index ${i} must be an object`));
      continue;
    }
    const rec = item as Record<string, unknown>;
    const id = rec.id;
    const status = rec.status;
    if (typeof id !== "string" || !id.trim()) {
      issues.push(issue(file, 1, "frontmatter.todos", `Todo at index ${i} missing string id`));
      continue;
    }
    if (typeof status !== "string") {
      issues.push(
        issue(file, 1, "frontmatter.todos", `Todo "${id}" missing string status`),
      );
      continue;
    }
    if (!ALLOWED_STATUSES.has(status)) {
      issues.push(
        issue(
          file,
          1,
          "frontmatter.todo-status",
          `Todo "${id}" has unrecognized status "${status}"`,
        ),
      );
    }
    todos.push({
      id: id.trim(),
      content: typeof rec.content === "string" ? rec.content : undefined,
      status,
    });
  }

  if (typeof data.name !== "string" || !data.name.trim()) {
    issues.push(issue(file, 1, "frontmatter.schema", "Frontmatter requires non-empty name"));
  }
  if (typeof data.overview !== "string" || !data.overview.trim()) {
    issues.push(issue(file, 1, "frontmatter.schema", "Frontmatter requires non-empty overview"));
  }
  if (typeof data.isProject !== "boolean") {
    issues.push(issue(file, 1, "frontmatter.schema", "Frontmatter requires boolean isProject"));
  }

  const ids = todos.map((t) => t.id);
  const dupes = ids.filter((id, idx) => ids.indexOf(id) !== idx);
  if (dupes.length > 0) {
    issues.push(
      issue(
        file,
        1,
        "frontmatter.todos",
        `Duplicate todo ids: ${[...new Set(dupes)].join(", ")}`,
      ),
    );
  }

  if (todos.length > 1) {
    const last = todos[todos.length - 1];
    if (last.id !== PLAN_CLOSURE_ID) {
      issues.push(
        issue(
          file,
          1,
          "frontmatter.todos",
          `Multi-slice plans must end with todo id "${PLAN_CLOSURE_ID}"`,
        ),
      );
    }
  }

  if (issues.length > 0) {
    return { ok: false, issues };
  }

  return {
    ok: true,
    parsed: { data, todos, frontmatterEndLine },
  };
}

interface LineState {
  inFence: boolean;
  fenceMarker: string | null;
}

function updateFenceState(line: string, state: LineState): LineState {
  const match = line.match(/^(`{3,}|~{3,})(.*)$/);
  if (!match) {
    return state;
  }
  const marker = match[1]!;
  if (!state.inFence) {
    return { inFence: true, fenceMarker: marker[0]!.repeat(marker.length) };
  }
  if (marker[0] === state.fenceMarker?.[0] && marker.length >= (state.fenceMarker?.length ?? 0)) {
    return { inFence: false, fenceMarker: null };
  }
  return state;
}

export interface DocumentStructure {
  headings: { level: number; text: string; line: number }[];
  bodyStartLine: number;
}

export function scanDocumentStructure(content: string, bodyStartLine: number): DocumentStructure {
  const lines = content.split(/\r?\n/);
  const headings: DocumentStructure["headings"] = [];
  let state: LineState = { inFence: false, fenceMarker: null };

  for (let i = bodyStartLine; i < lines.length; i++) {
    const line = lines[i]!;
    state = updateFenceState(line, state);
    if (state.inFence) {
      continue;
    }
    const m = line.match(/^(#{1,6})\s+(.+?)\s*$/);
    if (m) {
      headings.push({
        level: m[1]!.length,
        text: m[2]!.trim(),
        line: i + 1,
      });
    }
  }

  return { headings, bodyStartLine };
}

function isActionableTodo(todo: PlanTodo): boolean {
  return todo.status === "pending" || todo.status === "in_progress";
}

function sliceHeadingMatchesTodo(headingText: string, todoId: string): boolean {
  const normalized = headingText.toLowerCase();
  if (todoId === PLAN_CLOSURE_ID) {
    return normalized.includes("plan closure");
  }
  if (normalized.includes(`— ${todoId}`) || normalized.includes(`- ${todoId}`)) {
    return true;
  }
  if (normalized.endsWith(` ${todoId}`) || normalized.includes(` ${todoId} `)) {
    return true;
  }
  const sliceDash = `slice — ${todoId}`;
  if (normalized.includes(sliceDash)) {
    return true;
  }
  return false;
}

function findSliceSection(
  content: string,
  bodyStartLine: number,
  todoId: string,
): { startLine: number; endLine: number; text: string } | null {
  const lines = content.split(/\r?\n/);
  let state: LineState = { inFence: false, fenceMarker: null };
  let start = -1;

  for (let i = bodyStartLine - 1; i < lines.length; i++) {
    const line = lines[i]!;
    state = updateFenceState(line, state);
    if (state.inFence) {
      continue;
    }
    const hm = line.match(/^##\s+(.+?)\s*$/);
    if (hm) {
      const text = hm[1]!.trim();
      if (start !== -1) {
        return {
          startLine: start,
          endLine: i,
          text: lines.slice(start - 1, i).join("\n"),
        };
      }
      if (sliceHeadingMatchesTodo(text, todoId)) {
        start = i + 1;
      }
    }
  }

  if (start !== -1) {
    return {
      startLine: start,
      endLine: lines.length,
      text: lines.slice(start - 1).join("\n"),
    };
  }
  return null;
}

function extractField(sectionText: string, field: string): { value: string; line: number } | null {
  const lines = sectionText.split(/\r?\n/);
  const pattern = new RegExp(`^\\*\\*${field}:\\*\\*\\s*(.*)$`);
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i]!.match(pattern);
    if (m) {
      const valueParts = [m[1] ?? ""];
      for (let j = i + 1; j < lines.length; j++) {
        const next = lines[j]!;
        if (/^\*\*[^*]+:\*\*/.test(next) || /^##\s/.test(next)) {
          break;
        }
        if (next.trim() === "") {
          valueParts.push("");
          continue;
        }
        if (/^[-*]\s/.test(next) || /^\d+\.\s/.test(next)) {
          valueParts.push(next);
          continue;
        }
        valueParts.push(next);
      }
      return { value: valueParts.join("\n").trim(), line: i + 1 };
    }
  }
  return null;
}

function parseAuthorityTable(content: string, bodyStartLine: number): Map<string, AuthorityLabel> {
  const lines = content.split(/\r?\n/);
  const map = new Map<string, AuthorityLabel>();
  let state: LineState = { inFence: false, fenceMarker: null };
  let inTable = false;

  for (let i = bodyStartLine - 1; i < lines.length; i++) {
    const line = lines[i]!;
    state = updateFenceState(line, state);
    if (state.inFence) {
      continue;
    }
    if (/^##\s+Recommended execution authority/i.test(line)) {
      inTable = true;
      continue;
    }
    if (inTable && /^##\s+/.test(line) && !/^###/.test(line)) {
      break;
    }
    if (!inTable) {
      continue;
    }
    if (!line.trim().startsWith("|")) {
      continue;
    }
    if (/^\|\s*[-—]+\s*\|/.test(line)) {
      continue;
    }
    const cells = line
      .split("|")
      .map((c) => c.trim())
      .filter((_, idx, arr) => idx > 0 && idx < arr.length - 1);
    if (cells.length < 2) {
      continue;
    }
    const sliceCell = cells[0]!
      .replace(/\*\*/g, "")
      .trim()
      .toLowerCase();
    const authorityCell = cells[1]!.replace(/\*\*/g, "").trim();
    if (sliceCell === "slice" || sliceCell.includes("recommended authority")) {
      continue;
    }
    const normalized = normalizeAuthority(authorityCell);
    if (normalized) {
      map.set(sliceCell.replace(/\s+/g, "-"), normalized);
      map.set(sliceCell.replace(/-/g, " "), normalized);
      map.set(sliceCell, normalized);
    }
  }

  return map;
}

function findRepoDefaultLine(content: string, bodyStartLine: number): number | null {
  const lines = content.split(/\r?\n/);
  let state: LineState = { inFence: false, fenceMarker: null };
  for (let i = bodyStartLine - 1; i < lines.length; i++) {
    const line = lines[i]!;
    state = updateFenceState(line, state);
    if (state.inFence) {
      continue;
    }
    if (/^##\s+Agent prompts/i.test(line)) {
      break;
    }
    if (/^Repo default:/i.test(line.trim())) {
      return i + 1;
    }
  }
  return null;
}

function findAgentPromptsSection(
  content: string,
  bodyStartLine: number,
): { startLine: number; endLine: number; text: string } | null {
  const lines = content.split(/\r?\n/);
  let state: LineState = { inFence: false, fenceMarker: null };
  let start = -1;

  for (let i = bodyStartLine - 1; i < lines.length; i++) {
    const line = lines[i]!;
    state = updateFenceState(line, state);
    if (state.inFence) {
      continue;
    }
    if (/^##\s+Agent prompts \(copy\/paste for Cursor\)/i.test(line)) {
      start = i + 1;
      continue;
    }
    if (start !== -1 && /^##\s+/.test(line) && !/^###/.test(line)) {
      return {
        startLine: start,
        endLine: i,
        text: lines.slice(start - 1, i).join("\n"),
      };
    }
  }

  if (start !== -1) {
    return {
      startLine: start,
      endLine: lines.length,
      text: lines.slice(start - 1).join("\n"),
    };
  }
  return null;
}

function parsePromptBlocks(sectionText: string, sectionStartLine: number): Map<string, { body: string; line: number }> {
  const lines = sectionText.split(/\r?\n/);
  const map = new Map<string, { body: string; line: number }>();
  let state: LineState = { inFence: false, fenceMarker: null };
  let currentId: string | null = null;
  let fenceStart = -1;
  let fenceContent: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!;
    const absLine = sectionStartLine + i;

    if (!state.inFence) {
      const hm = line.match(/^###\s+(.+?)\s*$/);
      if (hm) {
        currentId = hm[1]!.trim();
        continue;
      }
    }

    const before = state.inFence;
    state = updateFenceState(line, state);

    if (!before && state.inFence) {
      fenceStart = absLine + 1;
      fenceContent = [];
      continue;
    }

    if (before && state.inFence) {
      fenceContent.push(line);
      continue;
    }

    if (before && !state.inFence && currentId) {
      map.set(currentId, { body: fenceContent.join("\n"), line: fenceStart });
      currentId = null;
      fenceContent = [];
    }
  }

  return map;
}

function parseLabeledPromptLines(block: string): Record<string, string> {
  const labels = ["Authority", "Topology", "Deliverables", "Verification", "Repositories"] as const;
  const result: Record<string, string> = {};
  for (const label of labels) {
    const re = new RegExp(`^${label}:\\s*(.*)$`, "im");
    const m = block.match(re);
    if (m) {
      result[label] = m[1]!.trim();
    }
  }
  return result;
}

function isEllipsisPlaceholder(value: string): boolean {
  const trimmed = value.trim();
  if (!trimmed) {
    return true;
  }
  return ELLIPSIS_PLACEHOLDER.test(trimmed);
}

function authorityAllowsMissingAcceptance(authority: AuthorityLabel | null): boolean {
  return (
    authority === "Plan-only PR" ||
    authority === "Manual verification gate" ||
    authority === null
  );
}

export function validatePlanContent(
  content: string,
  file: string,
  options: ValidatePlanOptions = {},
): PlanIssue[] {
  const profile = options.profile ?? "default";
  const config = options.config ?? {};
  const issues: PlanIssue[] = [];

  const fmResult = parsePlanFrontmatter(content, file);
  if (!fmResult.ok) {
    return fmResult.issues;
  }

  const { todos, frontmatterEndLine } = fmResult.parsed;
  const bodyStartLine = frontmatterEndLine + 1;
  const structure = scanDocumentStructure(content, bodyStartLine);

  const hasAuthoritySection = structure.headings.some(
    (h) => h.level === 2 && /^Recommended execution authority/i.test(h.text),
  );
  if (!hasAuthoritySection) {
    issues.push(
      issue(
        file,
        bodyStartLine,
        "plan.authority-table",
        'Missing "## Recommended execution authority" section',
      ),
    );
  }

  const requireRepoDefault = config.requireRepoDefaultLine !== false;
  if (requireRepoDefault) {
    const repoDefaultLine = findRepoDefaultLine(content, bodyStartLine);
    if (!repoDefaultLine) {
      issues.push(
        issue(
          file,
          bodyStartLine,
          "plan.repo-default",
          'Missing plan-level "Repo default:" line',
        ),
      );
    }
  }

  const authorityTable = parseAuthorityTable(content, bodyStartLine);

  for (const todo of todos) {
    if (!isActionableTodo(todo)) {
      continue;
    }

    const section = findSliceSection(content, bodyStartLine, todo.id);
    if (!section) {
      issues.push(
        issue(
          file,
          bodyStartLine,
          "slice.missing",
          `No ## slice section found for actionable todo "${todo.id}"`,
        ),
      );
      continue;
    }

    const recAuth = extractField(section.text, "Recommended authority");
    const rationale = extractField(section.text, "Rationale");
    const agentInstr = extractField(section.text, "Agent instruction");
    const acceptance = extractField(section.text, "Acceptance");

    const sliceLineOffset = section.startLine;

    if (!recAuth || !recAuth.value.trim()) {
      issues.push(
        issue(
          file,
          sliceLineOffset,
          "slice.recommended-authority",
          `Slice "${todo.id}" missing **Recommended authority:**`,
        ),
      );
    } else {
      const normalized = normalizeAuthority(recAuth.value.split("\n")[0] ?? recAuth.value);
      if (!normalized) {
        issues.push(
          issue(
            file,
            sliceLineOffset + recAuth.line - 1,
            "slice.authority-label",
            `Slice "${todo.id}" has unrecognized recommended authority "${recAuth.value.split("\n")[0]}"`,
          ),
        );
      } else {
        const tableKey = todo.id.toLowerCase();
        const tableAuth =
          authorityTable.get(tableKey) ??
          authorityTable.get(todo.id) ??
          authorityTable.get(todo.id.replace(/-/g, " "));
        if (tableAuth && tableAuth !== normalized) {
          issues.push(
            issue(
              file,
              sliceLineOffset + recAuth.line - 1,
              "authority.mismatch",
              `Slice "${todo.id}" authority "${normalized}" does not match authority table "${tableAuth}"`,
            ),
          );
        }
      }
    }

    if (!rationale || !rationale.value.trim()) {
      issues.push(
        issue(
          file,
          sliceLineOffset,
          "slice.rationale",
          `Slice "${todo.id}" missing **Rationale:**`,
        ),
      );
    }

    if (!agentInstr || !agentInstr.value.trim()) {
      issues.push(
        issue(
          file,
          sliceLineOffset,
          "slice.agent-instruction",
          `Slice "${todo.id}" missing **Agent instruction:**`,
        ),
      );
    }

    const sliceAuthority = recAuth
      ? normalizeAuthority(recAuth.value.split("\n")[0] ?? recAuth.value)
      : null;
    const skipAcceptance =
      todo.id === PLAN_CLOSURE_ID || authorityAllowsMissingAcceptance(sliceAuthority);

    if (!skipAcceptance && (!acceptance || !acceptance.value.trim())) {
      issues.push(
        issue(
          file,
          sliceLineOffset,
          "slice.acceptance",
          `Slice "${todo.id}" missing **Acceptance:**`,
        ),
      );
    }
  }

  const agentSection = findAgentPromptsSection(content, bodyStartLine);
  if (!agentSection) {
    issues.push(
      issue(
        file,
        bodyStartLine,
        "prompts.section",
        'Missing "## Agent prompts (copy/paste for Cursor)" section',
      ),
    );
  } else {
    const promptMap = parsePromptBlocks(agentSection.text, agentSection.startLine);
    const todoIds = new Set(todos.map((t) => t.id));

    for (const [headingId, block] of promptMap) {
      if (!todoIds.has(headingId)) {
        issues.push(
          issue(
            file,
            block.line - 1,
            "prompts.orphan",
            `Agent prompt heading "### ${headingId}" does not match any frontmatter todo id`,
          ),
        );
      }
    }

    for (const todo of todos) {
      if (!isActionableTodo(todo)) {
        continue;
      }

      const prompt = promptMap.get(todo.id);
      if (!prompt) {
        issues.push(
          issue(
            file,
            agentSection.startLine,
            "prompts.missing",
            `Actionable todo "${todo.id}" missing ### ${todo.id} agent prompt`,
          ),
        );
        continue;
      }

      const labeled = parseLabeledPromptLines(prompt.body);
      const requiredLabels = ["Authority", "Topology", "Deliverables", "Verification"] as const;

      for (const label of requiredLabels) {
        if (!labeled[label]?.trim()) {
          issues.push(
            issue(
              file,
              prompt.line,
              "prompts.labeled-lines",
              `Prompt for "${todo.id}" missing labeled line "${label}:"`,
            ),
          );
        }
      }

      if (labeled.Authority) {
        const normalized = normalizeAuthorityFromPromptLine(labeled.Authority);
        if (!normalized) {
          issues.push(
            issue(
              file,
              prompt.line,
              "prompts.authority-label",
              `Prompt for "${todo.id}" has unrecognized Authority label`,
            ),
          );
        } else {
          const section = findSliceSection(content, bodyStartLine, todo.id);
          const recAuth = section ? extractField(section.text, "Recommended authority") : null;
          const sliceAuth = recAuth
            ? normalizeAuthority(recAuth.value.split("\n")[0] ?? recAuth.value)
            : null;
          if (sliceAuth && sliceAuth !== normalized) {
            issues.push(
              issue(
                file,
                prompt.line,
                "authority.mismatch",
                `Prompt authority "${normalized}" does not match slice recommended authority "${sliceAuth}" for "${todo.id}"`,
              ),
            );
          }
        }
      }

      if (profile === "default") {
        for (const label of ["Deliverables", "Verification"] as const) {
          const value = labeled[label];
          if (value && isEllipsisPlaceholder(value)) {
            issues.push(
              issue(
                file,
                prompt.line,
                "prompts.placeholder",
                `Prompt for "${todo.id}" ${label} is only an ellipsis placeholder`,
              ),
            );
          }
        }
      }
    }

    const headingCounts = new Map<string, number>();
    const promptLines = agentSection.text.split(/\r?\n/);
    let fence: LineState = { inFence: false, fenceMarker: null };
    for (const line of promptLines) {
      fence = updateFenceState(line, fence);
      if (fence.inFence) {
        continue;
      }
      const hm = line.match(/^###\s+(.+?)\s*$/);
      if (hm) {
        const id = hm[1]!.trim();
        headingCounts.set(id, (headingCounts.get(id) ?? 0) + 1);
      }
    }
    for (const [headingId, count] of headingCounts) {
      if (count > 1) {
        issues.push(
          issue(
            file,
            agentSection.startLine,
            "prompts.duplicate",
            `Duplicate agent prompt heading "### ${headingId}" (${count} times)`,
          ),
        );
      }
    }
  }

  return issues;
}

export function validatePlanFile(
  filePath: string,
  options: ValidatePlanOptions = {},
): PlanIssue[] {
  const content = readFileSync(filePath, "utf8");
  return validatePlanContent(content, filePath, options);
}

function globToRegExp(globPattern: string): RegExp {
  const normalized = globPattern.replace(/\\/g, "/");
  let re = "^";
  for (let i = 0; i < normalized.length; i++) {
    const ch = normalized[i]!;
    if (ch === "*") {
      if (normalized[i + 1] === "*") {
        re += ".*";
        i++;
        if (normalized[i + 1] === "/") {
          i++;
        }
      } else {
        re += "[^/]*";
      }
    } else if (ch === "?") {
      re += "[^/]";
    } else if (ch === ".") {
      re += "\\.";
    } else {
      re += ch.replace(/[\\^$+?.()|[\]{}]/g, "\\$&");
    }
  }
  re += "$";
  return new RegExp(re);
}

function matchesAnyGlob(relPath: string, patterns: string[]): boolean {
  const norm = relPath.replace(/\\/g, "/");
  return patterns.some((p) => globToRegExp(p.replace(/\\/g, "/")).test(norm));
}

export async function discoverPlanFiles(
  repoRoot: string,
  config?: PlanValidatorConfig,
  includeArchive = false,
): Promise<string[]> {
  const plansGlobs = config?.plansGlobs ?? DEFAULT_PLANS_GLOBS;
  const excludeGlobs = [...(config?.excludeGlobs ?? DEFAULT_EXCLUDE_GLOBS)];
  if (includeArchive) {
    const filtered = excludeGlobs.filter((g) => !g.includes("archive"));
    excludeGlobs.length = 0;
    excludeGlobs.push(...filtered);
  }

  const files = new Set<string>();
  for (const pattern of plansGlobs) {
    const fullPattern = pattern.startsWith("/") ? pattern.slice(1) : pattern;
    for await (const entry of glob(join(repoRoot, fullPattern))) {
      if (entry.endsWith(".plan.md")) {
        files.add(resolve(entry));
      }
    }
  }

  const result: string[] = [];
  for (const file of [...files].sort()) {
    const rel = relative(repoRoot, file).replace(/\\/g, "/");
    if (matchesAnyGlob(rel, excludeGlobs)) {
      continue;
    }
    result.push(file);
  }
  return result;
}

export async function validatePlanPaths(
  paths: string[],
  options: ValidatePlanOptions & { repoRoot?: string; includeArchive?: boolean } = {},
): Promise<PlanIssue[]> {
  const repoRoot = options.repoRoot ?? process.cwd();
  const config = options.config ?? loadPlanValidatorConfig(repoRoot);
  const allIssues: PlanIssue[] = [];

  let files: string[];
  if (paths.length > 0) {
    files = paths.map((p) => (p.startsWith("/") ? p : resolve(repoRoot, p)));
  } else {
    files = await discoverPlanFiles(repoRoot, config, options.includeArchive ?? false);
  }

  for (const file of files) {
    try {
      const issues = validatePlanFile(file, { ...options, config });
      allIssues.push(...issues);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      allIssues.push(issue(file, 1, "io.error", message));
    }
  }

  return allIssues;
}

export function formatPlanIssues(issues: PlanIssue[]): string {
  return issues
    .map((i) => `${i.file}:${i.line}: [${i.rule}] ${i.message}`)
    .join("\n");
}
