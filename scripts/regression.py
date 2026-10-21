#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import time
from pathlib import Path


def run_test(name: str, command: str, log_dir: Path) -> dict:
    log_path = log_dir / f"{name}.log"
    start = time.time()

    with log_path.open("w") as log:
        result = subprocess.run(
            command,
            shell=True,
            executable="/bin/bash",
            stdout=log,
            stderr=subprocess.STDOUT,
            env=os.environ.copy(),
            check=False,
        )

    elapsed = time.time() - start

    return {
        "test": name,
        "command": command,
        "exit_code": result.returncode,
        "status": "PASS" if result.returncode == 0 else "FAIL",
        "elapsed_seconds": round(elapsed, 3),
        "log": str(log_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tests", nargs="+", default=["sanity", "dma"])
    parser.add_argument("--log-dir", default="results/logs")
    parser.add_argument(
        "--command-template",
        default="make sim TEST={test}",
        help="Simulation command template; {test} is replaced by test name",
    )
    args = parser.parse_args()

    log_dir = Path(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)

    results = []

    for test in args.tests:
        command = args.command_template.format(test=test)
        print(f"Running {test}: {command}")

        result = run_test(test, command, log_dir)
        results.append(result)

        print(f"  {result['status']} ({result['elapsed_seconds']} s)")

    report = {
        "total": len(results),
        "passed": sum(r["status"] == "PASS" for r in results),
        "failed": sum(r["status"] == "FAIL" for r in results),
        "results": results,
    }

    report_path = log_dir / "regression_summary.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")

    print(f"\nSummary: {report['passed']}/{report['total']} passed")
    print(f"Report: {report_path}")

    return 1 if report["failed"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
