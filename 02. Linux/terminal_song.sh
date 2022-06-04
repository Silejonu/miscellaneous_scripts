#!/usr/bin/bash

cat /dev/urandom | \
hexdump -e '/1 "%u " /1 "%u\n"' | \
awk '{ split("0,2,4,5,7,8,10,12",a,",");split("0.25,0.25,0.25,0.5,0.5,1",b,",");for (i = 0; i < b[$2 %7]; i+= 0.0001) printf("%08X\n", 100*sin(1382*2**(a[$1 %9]/12)*i)) }' | \
xxd -r -p | \
aplay -c 2 -f S32_LE -r 16000


# Taken from https://www.reddit.com/r/linuxmemes/comments/v4nl8x/comment/ib57gyo
