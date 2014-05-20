#! /bin/sh
#--------------------------------------------------------------------
# SETUP GLOBAL VARIABLES
#--------------------------------------------------------------------
DATAFILE=$1
PATH_FIFO=/tmp/fifo_$( basename ${0%.*} )
trap "rm -f $PATH_FIFO" SIGINT SIGTERM SIGQUIT
#--------------------------------------------------------------------
# MAIN SCRIPT
#--------------------------------------------------------------------
if [ $# -eq 0 ] ; then
    echo "Usage: $0 HTTPD_ACCESS_LOG"
    exit 1
fi
if [ ! -r "$1" ] ; then
    echo "Fail: Cannot read $1."
    exit 1
fi
echo ">> make temporary FIFO: $PATH_FIFO"
mkfifo $PATH_FIFO
if [ $? != 0 ]; then
    echo "Fail: Cannot make fifo: $PAHT_FIFO"
    exit 1
fi

# 7th field means URI
eval "cut -d \" \" -f 7 $DATAFILE |
awk 'BEGIN { n_total_hits=0; }
/\/.*\.(php|html|htm|wm.*|txt)/ { uri=match(\$1,/[^?]+/); print substr(\$1,RSTART,RLENGTH); n_total_hits++; }
END { printf \"%d\n\", n_total_hits >>\"${PATH_FIFO}\"; }
' | sort | uniq -c | sort -r -k 1 >>${PATH_FIFO} &"

# print result set
cat $PATH_FIFO |
awk ' { if (NR == 1) { n_total_hits=$1; print "Total Hits :", n_total_hits; print "Hits ,     %  : URI"; } else { printf "%3d, %5.2f %%  : %s\n", $1, ($1*100)/n_total_hits, $2; } }
'
# call bail handler via signal
kill -QUIT $$


