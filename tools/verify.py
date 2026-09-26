#!/usr/bin/env python3
"""Run Godot checks with deadlines and log-error gates, not exit codes alone."""
from pathlib import Path
import argparse
import json
import os
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"
ERRORS = re.compile(r"SCRIPT ERROR|Parse Error|^ERROR:|^FAIL:|\bFAILURES:", re.MULTILINE)


def run(label, arguments, timeout=60):
    started = time.monotonic()
    command = [os.environ.get("GODOT_BIN", "godot"), "--path", str(ROOT), *arguments]
    try:
        process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
        output = process.stdout + process.stderr
        code = process.returncode
    except subprocess.TimeoutExpired as error:
        output = f"FAIL: timed out after {timeout}s\n{error}"
        code = 124
    (ARTIFACTS / f"{label}.log").write_text(output)
    passed = code == 0 and not ERRORS.search(output)
    checks = 0
    summary = re.search(r"(\d+)/(\d+) checks passed", output)
    legacy = re.search(r"Total assertions: (\d+)\s+Pass: (\d+)\s+Fail: (\d+)", output)
    if label.startswith("test_"):
        if summary:
            checks = int(summary[2])
            passed = passed and int(summary[1]) == checks and checks > 0
        elif legacy:
            checks = int(legacy[1])
            passed = passed and int(legacy[2]) == checks and int(legacy[3]) == 0 and checks > 0
        else:
            passed = False
    if label == "capture":
        passed = passed and "LIVE: counters=1 chains=1 score=587 hp=3" in output
    print(f"{'PASS' if passed else 'FAIL'} {label}: {checks} assertions; {time.monotonic()-started:.2f}s")
    if not passed:
        print(output)
    return {"name": label, "passed": bool(passed), "checks": checks, "exit_code": code}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--render", action="store_true", help="also open a real GL window and capture gameplay")
    options = parser.parse_args()
    ARTIFACTS.mkdir(exist_ok=True)
    results = [run("import", ["--headless", "--import", "--quit"], 120)]
    if results[0]["passed"]:
        for test in sorted((ROOT / "tests").glob("test_*.gd")):
            results.append(run(test.stem, ["--headless", "--script", str(test)], 60))
    if options.render and all(result["passed"] for result in results):
        results.append(run("capture", ["--script", "tests/capture_scene.gd"], 120))
    payload = {"passed": all(result["passed"] for result in results),
               "total_assertions": sum(result["checks"] for result in results),
               "render_requested": options.render, "results": results}
    (ARTIFACTS / "verification.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 0 if payload["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
