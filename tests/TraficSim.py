import struct
import numpy as np
from scapy.all import rdpcap, IP, TCP, conf

def activation(sum_val):
    return 1.0 if sum_val >= 0 else 0.0

def float_to_hex32(value: float) -> str:
    v32 = np.float32(value)
    b = struct.pack('>f', float(v32))
    u32, = struct.unpack('>I', b)
    return f"{u32:08X}"

def read_trained_weights(filename):
    weights = []
    try:
        with open(filename, "r") as f:
            lines = f.readlines()
            read_floats = False
            for line in lines:
                line = line.strip()
                if line == "FLOAT_WEIGHTS:":
                    read_floats = True
                    continue
                if line == "HEX_IEEE754_WEIGHTS:" or line == "":
                    read_floats = False
                    continue
                
                if read_floats:
                    weights.append(float(line))
    except FileNotFoundError:
        print(f"Eroare: Fisierul {filename} nu a fost gasit.")
        weights = [0.05, -0.02, 0.1] 
    return weights

def extract_features(packet):
    f1, f2 = 0.0, 0.0
    if IP in packet:
        f1 = len(packet) / 1500.0  
        f2 = packet[IP].ihl / 15.0 
    return [f1, f2]

def evaluate_packet(packet, weights):
    features = extract_features(packet)
    
    x_input = features + [1.0]
    
    if len(x_input) != len(weights):
        raise ValueError("Dimensiunea vectorului de intrare nu corespunde cu numarul de ponderi.")
    
    s = sum(x * w for x, w in zip(x_input, weights))
    
    prediction = activation(s)
    
    return features, s, prediction

if __name__ == "__main__":
    WEIGHTS_FILE = "trained_weights.txt"
    PCAP_FILE = "sample_traffic.pcap" 
    
    print("Incarcare ponderi model...")
    w = read_trained_weights(WEIGHTS_FILE)
    print(f"Ponderi incarcate: {w}")
    
    print(f"\nProcesare trafic din: {PCAP_FILE}...")
    try:
        packets = rdpcap(PCAP_FILE)
        
        for i, pkt in enumerate(packets[:10]): 
            if IP in pkt:
                features, net_sum, is_anomaly = evaluate_packet(pkt, w)
                
                status = "🚨 INTRUZIUNE DETECTATA" if is_anomaly == 1 else "✅ Normal"
                print(f"Pachet {i+1} | Trasaturi extrase: [{features[0]:.4f}, {features[1]:.4f}] | Suma Net: {net_sum:.4f} | Status: {status}")
                
    except FileNotFoundError:
        print(f"Fisierul {PCAP_FILE} nu exista. Creeaza o captura scurtă din Wireshark pentru a testa.")