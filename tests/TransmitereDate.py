import struct
import numpy as np


def fixed_list(lst, n):
    x2 = []
    finlist = []
    for x in lst:
        x2.append(x)
        if len(x2) == n:
            finlist.append(x2)
            x2 = []
    if len(x2) > 0:
        print("Warning: list size is not multiple of n, ignoring last incomplete group:", x2)
    return finlist


def read_two_lists(filename):
    with open(filename, "r") as f:
        lines = f.read().splitlines()
    if len(lines) < 2:
        raise ValueError("Fisierul trebuie sa contina 2 linii.")
    list1 = list(map(float, lines[0].split()))
    list2 = list(map(float, lines[1].split()))
    return list1, list2


def float_to_hex32(value: float) -> str:
    v32 = np.float32(value)
    b = struct.pack('>f', float(v32))
    u32, = struct.unpack('>I', b)
    return f"{u32:08X}"

def save_training_data_ieee754_hex(X, y, filename):
    num_samples = len(X)
    num_features = len(X[0]) if num_samples > 0 else 0
    num_words_per_sample = num_features + 1  

    with open(filename, "w") as f:
        f.write(f"{num_samples} {num_words_per_sample}\n")
        for x_i, d_i in zip(X, y):
            hex_features = [float_to_hex32(val) for val in x_i]
            hex_label = float_to_hex32(d_i)
            line = " ".join(hex_features + [hex_label])
            f.write(line + "\n")


def save_expected_outputs_decimal(y, filename):
    with open(filename, "w") as f:
        f.write(f"{len(y)}\n")
        for i, d in enumerate(y):
            f.write(f"{i} {d}\n")


if __name__ == "_main_":
    INPUT_FILE = "fisierInputs.txt"
    NUM_FEATURES = 2
    TRAINING_OUT_FILE = "training_ieee32or.txt"
    OUTPUTS_FILE = "outputs_expected.txt"

    list1, list2 = read_two_lists(INPUT_FILE)
    X = fixed_list(list1, NUM_FEATURES)

    num_samples = len(X)
    if num_samples == 0:
        raise ValueError("Nu exista exemple de intrare (X este gol).")

    if len(list2) != num_samples:
        raise ValueError(
            f"Numarul de etichete ({len(list2)}) nu corespunde cu numărul de exemple ({num_samples})."
        )

    y = [float(d) for d in list2]

    X_bias = [x_i + [1.0] for x_i in X]

    save_training_data_ieee754_hex(X_bias, y, TRAINING_OUT_FILE)
    print(f"Dataset salvat in {TRAINING_OUT_FILE}")

    save_expected_outputs_decimal(y, OUTPUTS_FILE)
    print(f"Expected outputs salvate in {OUTPUTS_FILE}")