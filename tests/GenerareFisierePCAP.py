from scapy.all import IP, TCP, ICMP, Raw, wrpcap
import random

def genereaza_trafic_normal(nume_fisier, numar_pachete=50):
    pachete = []
    for _ in range(numar_pachete):
        ip = IP(src=f"192.168.1.{random.randint(2, 254)}", dst="10.0.0.5")
        tcp = TCP(sport=random.randint(1024, 65535), dport=80, flags="PA")
        payload = Raw(b"GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" + b"A" * random.randint(100, 500))
        pachete.append(ip/tcp/payload)
    
    wrpcap(nume_fisier, pachete)
    print(f"✅ Generat: {nume_fisier} ({numar_pachete} pachete)")

def genereaza_atac_dos_syn(nume_fisier, numar_pachete=100):
    pachete = []
    for _ in range(numar_pachete):
        ip = IP(src=f"10.0.0.{random.randint(1, 254)}", dst="192.168.1.100")
        tcp = TCP(sport=random.randint(1024, 65535), dport=80, flags="S")
        pachete.append(ip/tcp)
    
    wrpcap(nume_fisier, pachete)
    print(f"Generat: {nume_fisier} ({numar_pachete} pachete)")

def genereaza_pachete_malformate(nume_fisier, numar_pachete=20):
    pachete = []
    for _ in range(numar_pachete):
        ip = IP(src="172.16.0.5", dst="192.168.1.100", ihl=random.randint(6, 15))
        tcp = TCP(sport=random.randint(1024, 65535), dport=22, flags="FPU") #Flag uri 
        pachete.append(ip/tcp)
    
    wrpcap(nume_fisier, pachete)
    print(f" Generat: {nume_fisier} ({numar_pachete} pachete)")

if __name__ == "__main__":
    print("Incepere generare")
    
    genereaza_trafic_normal("trafic_normal.pcap")
    genereaza_atac_dos_syn("atac_dos_syn.pcap")
    genereaza_pachete_malformate("pachete_malformate.pcap")
    
    print("\nGenerare completa")