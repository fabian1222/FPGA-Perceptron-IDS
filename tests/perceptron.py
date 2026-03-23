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

    with open(filename, "w") as f:
        f.write(f"{num_samples} {num_features+1}\n")
        for x_i, d_i in zip(X, y):
            hex_features = [float_to_hex32(val) for val in x_i]
            hex_label = float_to_hex32(d_i)
            f.write(" ".join(hex_features + [hex_label]) + "\n")


def save_expected_outputs_decimal(y, filename):
    with open(filename, "w") as f:
        f.write(f"{len(y)}\n")
        for i, d in enumerate(y):
            f.write(f"{i} {d}\n")




def weighted_sum(x, w):
    return sum([a*b for a, b in zip(x, w)])


def activation(sum_val):
    return 1.0 if sum_val >= 0 else 0.0


def learn_weights(X, y, alpha=0.1, epochs=20):
    
    num_features = len(X[0])
    w = [0.0] * num_features   # initializare la zero

    for _ in range(epochs):
        for x_i, d_i in zip(X, y):
            s = weighted_sum(x_i, w)
            out = activation(s)
            error = d_i - out
            # update perceptron
            for j in range(num_features):
                w[j] = w[j] + alpha * error * x_i[j]

    return w


def save_weights_float_and_hex(weights, filename):
    with open(filename, "w") as f:
        f.write("FLOAT_WEIGHTS:\n")
        for w in weights:
            f.write(f"{w}\n")

        f.write("\nHEX_IEEE754_WEIGHTS:\n")
        for w in weights:
            f.write(float_to_hex32(w) + "\n")




if __name__ == "__main__":
    INPUT_FILE = "fisierInputs.txt"
    NUM_FEATURES = 2
    TRAINING_OUT_FILE = "or.txt"
    OUTPUTS_FILE = "outputs_expected.txt"
    WEIGHTS_OUT_FILE = "trained_weights.txt"

    list1, list2 = read_two_lists(INPUT_FILE)
    X = fixed_list(list1, NUM_FEATURES)

    if len(X) == 0:
        raise ValueError("Nu exista exemple X.")

    if len(list2) != len(X):
        raise ValueError("Numarul etichetelor != numarul exemplarelor.")

    y = [float(d) for d in list2]

    
    X_bias = [x_i + [1.0] for x_i in X]

    save_training_data_ieee754_hex(X_bias, y, TRAINING_OUT_FILE)
    save_expected_outputs_decimal(y, OUTPUTS_FILE)

    
    weights = learn_weights(X_bias, y, alpha=0.1, epochs=30)

    print("Greutati invatate (float):")
    print(weights)

    save_weights_float_and_hex(weights, WEIGHTS_OUT_FILE)
    print(f"Greutati salvate in {WEIGHTS_OUT_FILE}")
