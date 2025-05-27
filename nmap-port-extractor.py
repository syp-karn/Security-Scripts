import re
import sys
import xml.etree.ElementTree as ET

def extract_from_normal(filename):
    ports = set()
    with open(filename, 'r') as file:
        for line in file:
            match = re.match(r'^(\d{1,5})/tcp\s+(open|filtered)', line)
            if match:
                ports.add(int(match.group(1)))
    return sorted(ports)

def extract_from_xml(filename):
    ports = set()
    try:
        tree = ET.parse(filename)
        root = tree.getroot()
        for port in root.findall(".//port"):
            protocol = port.attrib.get('protocol')
            state = port.find('state').attrib.get('state')
            portid = port.attrib.get('portid')
            if protocol == 'tcp' and state in ('open', 'filtered'):
                ports.add(int(portid))
    except Exception as e:
        print(f"[-] XML parsing error: {e}")
    return sorted(ports)

def save_ports(ports, out_file="ports.txt"):
    with open(out_file, 'w') as f:
        f.write(",".join(str(p) for p in ports))
    print(f"Ports saved to {out_file}:")
    print(",".join(str(p) for p in ports))

def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_ports.py <nmap_output_file>")
        sys.exit(1)

    filename = sys.argv[1]

    try:
        with open(filename, 'r') as f:
            first_line = f.readline()
            if first_line.strip().startswith('<?xml'):
                ports = extract_from_xml(filename)
            else:
                ports = extract_from_normal(filename)
    except Exception as e:
        print(f"[-] Error reading file: {e}")
        sys.exit(1)

    if ports:
        save_ports(ports)
    else:
        print("[-] No open or filtered TCP ports found.")

if __name__ == "__main__":
    main()
