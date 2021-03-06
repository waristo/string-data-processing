#!/bin/bash

# directory tree
:<<END
Dir
  -source file
  -reference directory
    -JTBC_2017_0101_0000
      -data
        -JTBC_2017_0101_0000.tok
        -JTBC_2017_0101_0000.text
          ...
  -SrcDir
    -run.sh
    -num_punct_process.go
    -num_punct_process_windows
    -num_punct_process_linux
END

#usage
:<<END
all files must UTF-8 encoding
Source file should not have an empty line.
source file path don't contain ../sourceFileName just sourceFileName
reference directory path don't contain ../ref_dir_path just ref_dir_path

./run.sh (source) (ref) (os) (outputname) 
ex) ./run.sh SubtTV_2017_01_03_pcm.list.trn broadcast_text/KOR windows 20170103

os flag = [windows, linux, build(build your os version exec file)]
os flag : build => it needs golang env.
source file line format :  (Don't care)/(Don't care)/(Don't care)/(Don't care)/JTBC_2017_0101_0000/JTBC_2017_0101_0000_999_000.pcm :: blah blah
END


####start###

if [ $# -ne 4 ]; then
  echo "./run.sh (source) (ref) (os) (outputname)"
  exit
fi

source=${1}
ref=${2}
os=${3}
output=${4}

# for remove empty line

:<<END
echo $(date) "remove empty line ${source}"
awk 'NF > 0' ../${source} > ../${source}.emp
cat ../${source}.emp > ../${source}
rm ../${source}.emp
END

# for change to utf-8
:<<END
target="*.tok"
org="euc-kr"
chg="utf-8"

list=`find ../${ref} -name "${target}"`
for filename in ${list}
do
  iconv -c -f ${org} -t ${chg} ${filename} > ${filename}.fix
  cat ${filename}.fix > ${filename}
  rm ${filename}.fix
done
END

sourceLine=$(cat ../${source} | wc -l)

if [ ${os} == "windows" ]; then
    # for matching
  echo $(date) "matching start" ${output}
  ./num_punct_process_windows -goal matching -source ${source} -ref ${ref} -output ${output}
    # for checking
  echo $(date) "checking start" ${output}
  ./num_punct_process_windows -goal checking -source ${source} -ref ${ref} -output ${output}
elif [ ${os} == "linux" ]; then
  echo $(date) "matching start" ${output}
  ./num_punct_process_linux -goal matching -source ${source} -ref ${ref} -output ${output}
  echo $(date) "checking start" ${output}
  ./num_punct_process_linux -goal checking -source ${source} -ref ${ref} -output ${output}
elif [ ${os} == "build" ]; then
  #   It needs golang env.
  echo "build golang exec file"
  go build -o num_punct_process num_punct_process.go 
  echo $(date) "matching start" ${output}
  ./num_punct_process -goal matching -source ${source} -ref ${ref} -output ${output}
  echo $(date) "checking start" ${output}
  ./num_punct_process -goal checking -source ${source} -ref ${ref} -output ${output}
else
  echo "Wrong Os flag Usage -windows, linux, build"
  exit
fi

#for file merge
echo $(date) "file merge ${output}.."
cat ../${output}_match_w_num ../${output}_match_wo_num > ../${output}_match 

#if you want miss file
cat ../${output}_miss_w_num ../${output}_miss ../${output}_miss_wo_num > ../${output}_miss

cat ../${output}_miss ../${output}_match ../${output}_fail > ../${output}_merge


#   for file sort
echo $(date) "file sort ${output} .."
cat ../${output}_merge | sort -k 1 > ../${output}

#if you want sort miss file
:<<END
cat ../miss | sort -k 1 > ../miss_s
END

successLine=$(cat ../${output}_match | wc -l)
let per=successLine\*100/sourceLine

#for removing log files
:<<END
echo $(date) "remove log files ${output} .."
rm ../${output}_*
END

echo "source line :" ${sourceLine}
echo "matching line :" ${successLine}
echo "Processing Rate :" ${per} "%"
