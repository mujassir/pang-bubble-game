"""Generate the game's tiny sound effects (no third-party audio).

Run from the project root:  python3 tools/make_sounds.py
Uses only the Python standard library.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "sounds")


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32000)) for s in samples))
    print("wrote", path)


def sweep(f0, f1, dur, wave_fn, vol=0.35, noise=0.0):
    n = int(RATE * dur)
    phase = 0.0
    out = []
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        phase += f / RATE
        s = wave_fn(phase) * (1.0 - t) ** 1.5
        if noise:
            s = s * (1 - noise) + random.uniform(-1, 1) * noise * (1.0 - t) ** 3
        out.append(s * vol)
    return out


def sine(p):
    return math.sin(2 * math.pi * p)


def square(p):
    return 1.0 if (p % 1.0) < 0.5 else -1.0


def saw(p):
    return 2.0 * (p % 1.0) - 1.0


def notes(freqs, dur, last_dur=None, vol=0.25):
    out = []
    for i, f in enumerate(freqs):
        d = last_dur if (last_dur and i == len(freqs) - 1) else dur
        out += sweep(f, f, d, square, vol)
    return out


random.seed(1)
write("shoot", sweep(600, 1300, 0.12, square, 0.18))
write("pop", sweep(900, 180, 0.16, sine, 0.5, noise=0.35))
write("powerup", notes([523, 659, 784, 1047], 0.07))
write("hit", sweep(420, 70, 0.45, saw, 0.3))
write("clear", notes([523, 659, 784, 1047], 0.11, last_dur=0.35))
