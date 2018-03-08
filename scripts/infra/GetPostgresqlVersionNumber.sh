#!/usr/bin/env bash
# Get version number of postgresql
res=$(psql --version  2>/dev/null | cut -d' ' -f3|cut -d'.' -f1-2)
echo $res
