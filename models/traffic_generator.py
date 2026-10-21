#!/usr/bin/env python3
"""Simplified PCIe/AXI/DDR reference model for verification."""

from dataclasses import dataclass, field
from typing import Dict, List


@dataclass
class MemoryModel:
    data_width: int = 32
    memory: Dict[int, int] = field(default_factory=dict)
    errors: List[str] = field(default_factory=list)

    @property
    def bytes_per_word(self) -> int:
        return self.data_width // 8

    def write(self, address: int, value: int) -> None:
        if address < 0 or address % self.bytes_per_word:
            self.errors.append(f"Invalid write address: {address:#x}")
            return

        mask = (1 << self.data_width) - 1
        self.memory[address] = value & mask

    def read(self, address: int) -> int:
        if address < 0 or address % self.bytes_per_word:
            raise ValueError(f"Invalid read address: {address:#x}")

        return self.memory.get(address, 0)

    def check(self, address: int, expected: int) -> bool:
        actual = self.read(address)
        expected &= (1 << self.data_width) - 1

        if actual != expected:
            self.errors.append(
                f"Mismatch at {address:#x}: "
                f"expected={expected:#x}, actual={actual:#x}"
            )
            return False

        return True

    def write_burst(self, base: int, values: List[int]) -> None:
        for index, value in enumerate(values):
            address = base + index * self.bytes_per_word
            self.write(address, value)

    def read_burst(self, base: int, length: int) -> List[int]:
        return [
            self.read(base + i * self.bytes_per_word)
            for i in range(length)
        ]

    def report(self) -> None:
        print(f"Memory words written: {len(self.memory)}")
        print(f"Errors: {len(self.errors)}")

        for error in self.errors:
            print(f"ERROR: {error}")


def main() -> int:
    model = MemoryModel()

    expected = [0x1000 + i for i in range(16)]
    model.write_burst(0x1000, expected)

    actual = model.read_burst(0x1000, len(expected))

    for index, value in enumerate(expected):
        model.check(0x1000 + index * 4, value)

    assert actual == expected, "Reference-model readback failed"

    model.report()
    print("Reference-model smoke test PASSED")
    return 1 if model.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
