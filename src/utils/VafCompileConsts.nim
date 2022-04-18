import system
import strutils

const BRANCH* = staticExec("git rev-parse --abbrev-ref HEAD").replace("\n", "")
const TAG* = staticExec("git describe --tags --abbrev=0").replace("\n", "")
when defined(linux):
  const PLATFORM* = "linux"
when defined(windows):
  const PLATFORM* = "win32"
