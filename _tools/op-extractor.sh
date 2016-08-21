#!/bin/bash

# extract individual opcodes from the monolithic list, add front matter and prepare
# for splitting (@@@) into individual files

file="$1"
shift
games="bg1: $1\nbg2: $2\nbgee: $3\niwd1: $4\niwd2: $5\npst: $6"

sed -n '
/^[^}]*class="opcode"/,/<\/div>/ {
# bah, not sure why this is needed for some cases
  /opnumberdata/d
  /descriptionheading/d
  
  /class="opcode"/ { s,^[^=]*="op\([^"]*\)".*$,@@@\n---\nn: \1,p; t; }

  # 153 opcode names lack the extra spurious hex in brackets, so we must not be too specific
  /class="opnamedata"/ { s,^[^>]*>\([^[<]*\).*$,name: "\1",p; t; }

  /class="parameterdata"/ {
    s,^.*Parameter\s*#\([^:]*\):.*terdata">\s*\([^<]*\)<.*$,param\1: "\2",p
    t
  }

  /class="descriptiondata"/,/<\/div>/ {
    s,^\s*<div class="descriptiondata">,%%%\n---\n,
    s,</div>.*$,,
    p
  }
}' "$file" | uniq | sed "/---/,/%%%/ { /^\s*$/d; s,%%%,$games,g; /parameterheading/d; }"
