"""Independent byte-addressed oracle; deterministic, no third-party packages."""
from pathlib import Path
import random

def main():
    rng = random.Random(20261022)
    mem = bytearray(1024)
    rows = []
    def add(addr, data, mask, aw=0, wd=0, bh=0, rh=0, read=None):
        valid = addr < len(mem)
        base = addr & ~3
        if valid:
            for lane in range(4):
                if mask & (1 << lane):
                    mem[base+lane] = (data >> (lane*8)) & 255
        ra = addr if read is None else read
        exp = int.from_bytes(mem[ra & ~3:(ra & ~3)+4], 'little') if ra < 1024 else 0
        rows.append((addr,data,mask,aw,wd,bh,rh,ra,exp,0 if valid else 3,0 if ra<1024 else 3))
    for word in range(256):
        add(word*4, rng.getrandbits(32), 15)
    for mask in range(16):
        for aw,wd in [(0,0),(0,5),(5,0)]:
            add(0,rng.getrandbits(32),mask,aw,wd,7,7)
    for _ in range(512):
        addr = rng.randrange(256)*4
        if rng.randrange(8)==0:
            addr += 1024
        add(addr,rng.getrandbits(32),rng.randrange(16),rng.randrange(8),rng.randrange(8),rng.randrange(8),rng.randrange(8))
    # Invalid write must not alias a valid location.
    for addr in [1024,2048,0xfffffffc]:
        add(addr,0xdeadbeef,15,0,4,6,6,read=0)
    for word in range(256):
        add(word*4,0,0,read=word*4)
    Path('build').mkdir(exist_ok=True)
    Path('build/vectors.txt').write_text('\n'.join(' '.join(f'{v:x}' for v in row) for row in rows)+'\n')
    print(f'Generated {len(rows)} oracle vectors, seed=20261022')

if __name__ == '__main__':
    main()
