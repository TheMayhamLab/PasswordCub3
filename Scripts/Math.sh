#!/bin/bash
# Name:     Math.sh
# Purpose:  To do random math to generate CPU usage
# By:       Michael Vieau
# Created:  2019.09.04
# Modified: 2019.09.04
# Rev Level 0.1
# -------------------------------------------

while :
do

for i in `seq 0 10000`
  do
    let num${i}=$RANDOM
  done
  expr ${num10} \* ${num20} \* ${num30} >/dev/null
  expr ${num6000} \* ${num80} \* ${num1000} >/dev/null
done
