#!/bin/sh
# extract apache access log, v1.02
# sunyzero@gmail

# - Environment for analysis
# file_extensions : REGEX
# e.g.) file_extensions="php\|html\|htm\|wm.*\|txt"
file_extensions="php\|html\|htm\|txt\|wm.*"

# ---- End of environment -----
# list_uri : URI list
typeset -a list_uri
typeset -a list_uri_hits
typeset -i n_total_hits=0
typeset -i n_list_uri=0
typeset -i idx_list_uri=0

DATAFILE=$1
PATH_FIFO=/tmp/fifo_$( basename ${0%.*} )
prev_access_uri=

# -------------------- Func routine -----------------------
function analyze_uri_hit()
{
    access_uri="${1%%\?*}"
    access_uri_base=`basename $access_uri`
    access_uri_ext=`expr $access_uri_base : ".\+\.\(${file_extensions}\)"`

    if [ $? = 0 ]; then
        let n_total_hits++
        # on success pattern matching
        if [ ! "x${prev_access_uri}" = "x${access_uri}" ]; then
            idx_list_uri=${#list_uri[*]}
            prev_access_uri=${access_uri}
            list_uri[${idx_list_uri}]=${access_uri}
            list_uri_hits[${idx_list_uri}]=1
        else    
            # alternatives
            # list_uri_hits[${#list_uri[*]}]=`expr list_uri_hits[${#list_uri[*]}] + 1`
            # list_uri_hits[${#list_uri[*]}]=$((list_uri_hits[${#list_uri[*]}] + 1))

            # hit, increase one
            let list_uri_hits[${idx_list_uri}]++
        fi
    fi
}

# remove fifo when exit irregulary
trap "rm -f $PATH_FIFO" SIGINT SIGTERM SIGQUIT

# -------------------- Main routine -----------------------
if [ "x$DATAFILE" = "x" ]; then
    echo "Usage : $0 <access_log file> "
    exit 1;
fi

mkfifo $PATH_FIFO

# 7th field means URI
# send to fifo
cut -d " " -f 7 $DATAFILE | sort > $PATH_FIFO &

# read from FIFO
exec 0< $PATH_FIFO
while read strline; do
    analyze_uri_hit $strline
done 

# print output
n_list_uri=${#list_uri[*]}
typeset -i iter=0
echo "Total List : $n_list_uri, Total Hits : $n_total_hits"
echo "Hits ,     %  : URI"
until [ ${iter} = ${n_list_uri} ]; do
    percent_hits=`echo "scale=2; ( ${list_uri_hits[${iter}]}*100 )/$n_total_hits " | bc`
    printf "%3d, %5.2f %%  : %s\n" ${list_uri_hits[${iter}]} $percent_hits ${list_uri[${iter}]}
    let iter++
done | sort -r -k 1

# send signal to installed signal handler
kill -QUIT $$


