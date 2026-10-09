#!/usr/bin/env python3
import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100

def create_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(1)  # Mono
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(SAMPLE_RATE)
        raw_data = bytearray()
        for s in samples:
            # Clamp to 16-bit range
            val = int(max(-32767, min(32767, s * 32767)))
            raw_data.extend(struct.pack('<h', val))
        wf.writeframes(raw_data)
    print(f"Generated: {filename} ({len(samples)/SAMPLE_RATE:.2f}s)")

# 1. Ambience: Rain gentle loop (3 seconds seamless pink/brown noise rain)
def generate_rain_loop(filename, duration=3.0):
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    # Simple filtered noise generator
    b0, b1, b2 = 0.0, 0.0, 0.0
    random.seed(42)
    for i in range(num_samples):
        white = random.uniform(-1.0, 1.0)
        # Pink-ish noise filter
        b0 = 0.99765 * b0 + white * 0.0990460
        b1 = 0.96300 * b1 + white * 0.2965164
        b2 = 0.57000 * b2 + white * 1.0526913
        pink = b0 + b1 + b2 + white * 0.1848
        # Add random subtle drops
        drop = 0.0
        if random.random() < 0.003:
            drop = random.uniform(0.1, 0.3)
        samples[i] = (pink * 0.05 + drop) * 0.4
    
    # Crossfade ends for clean looping
    fade_len = int(SAMPLE_RATE * 0.1)
    for i in range(fade_len):
        fade_in = i / fade_len
        fade_out = 1.0 - fade_in
        samples[i] = samples[i] * fade_in + samples[num_samples - fade_len + i] * fade_out
    
    create_wav(filename, samples)

# 2. Ambience: Refrigerator hum loop (50Hz + subtle harmonics, 2 seconds)
def generate_fridge_hum(filename, duration=2.0):
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # 50Hz fundamental + 100Hz + 150Hz harmonic
        hum = 0.18 * math.sin(2 * math.pi * 50 * t) + \
              0.08 * math.sin(2 * math.pi * 100 * t) + \
              0.04 * math.sin(2 * math.pi * 150 * t)
        samples[i] = hum * 0.4
    create_wav(filename, samples)

# 3. Ambience: Clock tick loop (1 second loop with soft tick at t=0)
def generate_clock_tick(filename, duration=1.0):
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    tick_len = int(SAMPLE_RATE * 0.04)
    for i in range(tick_len):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 120.0)
        samples[i] = 0.25 * math.sin(2 * math.pi * 1800 * t) * decay
    create_wav(filename, samples)

# 4. SFX: Phone vibration (two soft buzz pulses)
def generate_phone_vibrate(filename):
    duration = 0.7
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    def add_pulse(start_t, pulse_len):
        start_idx = int(start_t * SAMPLE_RATE)
        len_idx = int(pulse_len * SAMPLE_RATE)
        for i in range(len_idx):
            if start_idx + i < num_samples:
                t = i / SAMPLE_RATE
                env = math.sin(math.pi * (i / len_idx))
                buzz = math.sin(2 * math.pi * 140 * t) * 0.4 + math.sin(2 * math.pi * 280 * t) * 0.2
                samples[start_idx + i] += buzz * env * 0.5
    add_pulse(0.05, 0.22)
    add_pulse(0.35, 0.25)
    create_wav(filename, samples)

# 5. SFX: Clock chime (deep resonant toll, 2.5 seconds)
def generate_clock_chime(filename, duration=2.5):
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    freqs = [220.0, 440.0, 660.0, 880.0, 1100.0]
    weights = [0.5, 0.3, 0.15, 0.08, 0.04]
    decays = [1.5, 2.2, 3.0, 4.0, 5.0]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        s = 0.0
        for f, w, d in zip(freqs, weights, decays):
            s += w * math.sin(2 * math.pi * f * t) * math.exp(-t * d)
        samples[i] = s * 0.6
    create_wav(filename, samples)

# 6. SFX: Chat type (gentle rounded bubble pop)
def generate_chat_type(filename):
    duration = 0.08
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 60.0)
        samples[i] = 0.3 * math.sin(2 * math.pi * (600 - t * 2000) * t) * env
    create_wav(filename, samples)

# 7. BGM: Fragment A Piano (4-note gentle melancholic phrase: A3, C4, B3, E3 with subtle reverb)
def synthesize_piano_note(freq, duration, decay_rate=2.0):
    num_samples = int(SAMPLE_RATE * duration)
    note_samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Piano timbre: fundamental + harmonics
        s = math.sin(2 * math.pi * freq * t) * 0.6 + \
            math.sin(2 * math.pi * freq * 2 * t) * 0.25 + \
            math.sin(2 * math.pi * freq * 3 * t) * 0.1
        env = math.exp(-t * decay_rate)
        # Gentle attack (5ms)
        if t < 0.005:
            env *= (t / 0.005)
        note_samples[i] = s * env * 0.35
    return note_samples

def generate_fragment_a(filename, reversed_version=False):
    # 4 notes: A3 (220.0), C4 (261.63), B3 (246.94), E3 (164.81)
    notes = [
        (220.0, 1.2),   # A3
        (261.63, 1.2),  # C4
        (246.94, 1.4),  # B3
        (164.81, 2.2)   # E3
    ]
    total_duration = 5.5
    num_samples = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * num_samples

    cur_time = 0.2
    for freq, dur in notes:
        note_data = synthesize_piano_note(freq, dur)
        start_idx = int(cur_time * SAMPLE_RATE)
        for i, val in enumerate(note_data):
            if start_idx + i < num_samples:
                samples[start_idx + i] += val
        cur_time += 1.1

    if reversed_version:
        # Reverse samples for nostalgic flashback effect (S07)
        samples.reverse()

    create_wav(filename, samples)

# 8. BGM: Warm single note (A3, warm gentle decay, 3.0s)
def generate_warm_single_note(filename):
    samples = synthesize_piano_note(220.0, 3.0, decay_rate=1.2)
    create_wav(filename, samples)

if __name__ == '__main__':
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    print("Generating Seven Moons Audio Assets...")
    generate_rain_loop(os.path.join(base_dir, "assets/audio/ambience/rain_gentle_loop.wav"))
    generate_fridge_hum(os.path.join(base_dir, "assets/audio/ambience/fridge_hum_loop.wav"))
    generate_clock_tick(os.path.join(base_dir, "assets/audio/ambience/clock_tick_loop.wav"))
    generate_phone_vibrate(os.path.join(base_dir, "assets/audio/sfx/phone_vibrate.wav"))
    generate_clock_chime(os.path.join(base_dir, "assets/audio/sfx/clock_chime.wav"))
    generate_chat_type(os.path.join(base_dir, "assets/audio/sfx/chat_type.wav"))
    generate_fragment_a(os.path.join(base_dir, "assets/audio/bgm/theme_fragment_a.wav"), False)
    generate_fragment_a(os.path.join(base_dir, "assets/audio/bgm/theme_fragment_a_reversed.wav"), True)
    generate_warm_single_note(os.path.join(base_dir, "assets/audio/bgm/theme_warm_single_note.wav"))
    print("Audio assets generated successfully!")
