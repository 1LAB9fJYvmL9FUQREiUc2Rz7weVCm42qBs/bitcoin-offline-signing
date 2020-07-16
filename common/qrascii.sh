#!/bin/bash
mytheme=${1:-"dark"}
encodingtype="ASCIIi"
[[ "${mytheme}" == "dark" ]] || encodingtype="ASCII"
qrencode -t ${encodingtype} | while IFS= read -r line; do echo -e "${line//#/\\u2588}"; done
