#!/usr/bin/env bash 
#
# Display per device  mounted partitions 
df |  awk '/^\/dev\// {printf "%s\t:%s\n",$6,$1}'
