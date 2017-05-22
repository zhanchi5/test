#! /usr/bin/env python3
# -*- coding: ASCII -*-
import subprocess
import dpkt
import socket
import sys
import datetime
from operator import itemgetter

f1 = open('top_tlk','w')

subprocess.check_call(
    ['sudo tcpdump -tnn -c 100 -w packets.pcap -i enp0s3'], shell=True)

f = open('packets.pcap')
pcap = dpkt.pcap.Reader(f)

packets = []
total_buf = 0
for ts, buf in pcap:
    total_buf += len(buf)
    eth = dpkt.ethernet.Ethernet(buf)
    ip = eth.data
    packet = {'IP_Src': socket.inet_ntoa(ip.src), 'IP_Dst': socket.inet_ntoa(
        ip.dst), 'Proto': type(ip.data), 'Size': len(buf)}
    packets.append(packet)
proto_packets = []
for packet in packets:
    if len(proto_packets) != 0:
        flag = 0
        for proto_packet in proto_packets:
            if packet['Proto'] == proto_packet['Proto']:
                flag = 1
                proto_packet['Amount'] += 1
                proto_packet['Size'] += packet['Size']
                break
        if flag == 0:
            buffer = {'Proto': packet['Proto'],
                      'Amount': 1, 'Size': packet['Size']}
            proto_packets.append(buffer)
    else:
        buffer = {'Proto': packet['Proto'],
                  'Amount': 1, 'Size': packet['Size']}
        proto_packets.append(buffer)
ip_packets = []
for packet in packets:
    if len(ip_packets) != 0:
        flag = 0
        for ip_packet in ip_packets:
            if packet['IP_Src'] == ip_packet['IP_Src']:
                flag = 1
                ip_packet['Size'] += packet['Size']
                ip_packet['Amount'] += 1
                break
        if flag == 0:
            buffer = {'IP_Src': packet['IP_Src'],
                      'Size': packet['Size'], 'Amount': 1}
            ip_packets.append(buffer)
    else:
        buffer = {'IP_Src': packet['IP_Src'],
                  'Size': packet['Size'], 'Amount': 1}
        ip_packets.append(buffer)
number_sort = sorted(ip_packets, key=itemgetter('Amount'), reverse=True)
size_sort = sorted(ip_packets, key=itemgetter('Size'), reverse=True)
proto_sort = sorted(proto_packets, key=itemgetter('Size'), reverse=True)
print ("These are the top talking IP addresses sorted by amount of packets :")
f1.write("These are the top talking IP addresses sorted by amount of packets:")
for packet in number_sort:
    print (packet['IP_Src'], "  ", packet['Amount'])
    f1.write("\n")
    f1.write("	")
    f1.write(str(packet['IP_Src']))
    f1.write("	")
    f1.write(str(packet['Amount']))
    f1.write("\n")
print ("These are the top talking IP addresses sorted by total bytes size :")
f1.write("These are the top talking IP addresses sorted by total bytes size :")
for packet in size_sort:
    print (packet['IP_Src'], "  ", packet['Size'])
    f1.write("\n")
    f1.write("	")
    f1.write(str(packet['IP_Src']))
    f1.write("	")
    f1.write(str(packet['Size']))
    f1.write("\n")
print ("These are the top used Protocols sorted by percentage of traffic :")
f1.write("These are the top used Protocols sorted by percentage of traffic :")
for packet in proto_sort:
    k = int((float(packet['Size']) / total_buf)*100) 
    print (packet['Proto'], "  ", int((float(packet['Size']) / total_buf) * 100), '%')
    f1.write("\n")
    f1.write("	")
    f1.write(str(packet['Proto']))
    f1.write("	")
    f1.write(str(k))
    f1.write(" %")
    f1.write("\n")
# What is the average packet rate? (packets/second)
# The last time stamp
# print "The packets/second %f " % (packets/(last-first))


# what is the protocol distribution?
# use dictionary

f1.close()
f.close()
sys.exit(0)
