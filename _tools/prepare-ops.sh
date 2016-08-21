#!/bin/bash

games=( "dummy" "bg1" "bg2" "bgee" "iwd1" "iwd2" "pst" )

function doGame() {
  file="$1"
  tdir="op_ex_$file"
  shift
  rm -rf $tdir
  mkdir $tdir
  cd $tdir

  ../../op-extractor.sh "../$file" $1 $2 $3 $4 $5 $6 | 
    csplit -s -b "-%03d" -n3 -z -f "${games[$7]}" - /@@@/ "{*}" # ideally -b "%d-${games[$7]}.html" -f "op"
  
  cd -
}

what=op_ex_pst.htm
debug() {
	return
	ls $1/$what -1 | sort | grep 99
}

echo ++++++++++++++++++++++++++++++++++++++++++++++++
echo Splitting opcodes
echo ++++++++++++++++++++++++++++++++++++++++++++++++
cd opcodes
n=1
for g in bg1tots.htm bg2tob.htm bgee.htm iwd1totl.htm iwd2.htm pst.htm; do
	# the vars are in correct order for this, HOWEVER this would make all the files unique
  #name=$(echo "0 0 0 0 0 0" | sed "s,0,1,$n")
  name="0 0 0 0 0 0"

  doGame "$g" $name $n
  let n++
done

debug .

echo ++++++++++++++++++++++++++++++++++++++++++++++++
echo Fixing opcode numbering
echo ++++++++++++++++++++++++++++++++++++++++++++++++
# fix naming of opcodes to match their numbers (caused by gaps)
function renumber() {
	find $1 -type f -name "$2" | sort -Vr |
	while read file; do
# 		[[ $file =~ htm ]] && continue
		sed -i '/@@@/d' "$file" # remove split marker
		inum=$(sed -n 's,^n: \(\S*\)$,\1,p' "$file")
		printf -v inum "%03d" $inum

		f=( $(sed "s,^\(.*\)/\([^/]*\)-\(.*\)$,\1/op$inum-\2.html \3 \2," <<<"$file") )
		nf=${f[0]}
		fnum=${f[1]}
		[[ -e $nf ]] && echo CONFLICT at $file : $nf : $inum: $fnum ||
		mv "$file" "$nf"
	done
}
renumber . "*-*"

debug .

# merge equal files and rename
echo ++++++++++++++++++++++++++++++++++++++++++++++++
echo Starting to dedupe
echo ++++++++++++++++++++++++++++++++++++++++++++++++
rm -rf op_joint
mkdir op_joint
cd op_joint

function dedupe() {
  find $1 -type f -exec md5sum {} + | sort |
  while read md file; do
    if [[ -n $omd && $md == $omd ]]; then
      nf=( $(sed 's,^.*/\([^-]*\)-\(.*\)\.html$,\1.html \2,' <<<"$file") )
      target=${nf[0]}

      mv "$ofile" "./$target"
      # save the target filename and games it was from
      echo "$target ${nf[1]}" >> op-map
      nf=( $(sed 's,^.*/\([^-]*\)-\(.*\)\.html$,\1.html \2,' <<<"$ofile") )
      echo "$target ${nf[1]}" >> op-map
    fi
    omd=$md
    ofile=$file
  done
}
dedupe ..

debug ..

echo ++++++++++++++++++++++++++++++++++++++++++++++++
echo Fixing front matter for singled opcodes
echo ++++++++++++++++++++++++++++++++++++++++++++++++
# assign games to front matter
#  first all filenames that still have dashes (meaning single game)
find .. -type f -name "op*-*" |
while read file; do
  game=$(sed 's,^[^-]*-\(.*\)\.html$,\1,' <<<"$file")
  sed -i "s,^$game: 0,$game: 1," "$file"
done

echo ++++++++++++++++++++++++++++++++++++++++++++++++
echo Fixing front matter for merged opcodes
echo ++++++++++++++++++++++++++++++++++++++++++++++++
#  secondly the merged ones, saved in op-map
while read file game; do
  sed -i "s,^$game: 0,$game: 1," "$file"
done < op-map
rm op-map

debug ..
