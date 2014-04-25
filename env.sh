#topN=15 #Comment this statement if you don't want to set topN value

# Arguments for rm and mv
RMARGS="-rf"
MVARGS="--verbose"

export NUTCH_JAVA_HOME=`java-config --jdk-home`
export NUTCH_CONF_DIR=`pwd`/conf

# Parse arguments
if [ "$1" == "safe" ]
then
  safe=yes
fi

if [ -z "$NUTCH_HOME" ]
then
  NUTCH_HOME=../apache-nutch-1.3/runtime/local
fi

if [ -n "$topN" ]
then
  topN="-topN $topN"
else
  topN=""
fi
