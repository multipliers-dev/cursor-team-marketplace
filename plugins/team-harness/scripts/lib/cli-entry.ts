import { realpathSync } from "node:fs";

/** True when Node was invoked via this module path or a symlink to it (e.g. npm `.bin`). */
export function isCliEntry(argv1: string | undefined, moduleFilePath: string): boolean {
  if (!argv1) {
    return false;
  }
  try {
    return realpathSync(argv1) === realpathSync(moduleFilePath);
  } catch {
    return false;
  }
}
