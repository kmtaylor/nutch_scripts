#!/bin/bash
trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG

cur_dir=`pwd`
index_name=`basename $cur_dir`
CRAWL_SUCCESSFUL=FALSE

update_status() {
    if [ $CRAWL_SUCCESSFUL = "TRUE" ] ; then
	echo COMPLETE > status
    else
	echo BROKEN > status
    fi
}

sanity_check() {
    # Try to fetch first file in 'urls'
    test_url=`head -1 urls`
    status=`./testsmb.sh conf/smb.properties $test_url 2>/dev/null | head -1`
    if ! echo $status | grep -q ': true' ; then
	# Couldn't contact SMB server, bail out
	return 1;
    fi
    # All good, ready to go
    return 0;
}

# Statuses:
# Inject	0 = Success, -1	An exception occured (IO)
# GenerateDB	0 = Success, -1 An exception occured (IO), no records selected
# Fetch		0 = Success, -1 Exception, handled in nutchbot.sh
# UpdateDB	0 = Success, -1 An exception occured (IO)
# Merge		Not explicit, javavm returns 1 on exceptions (IO)
# Invert	0 = Success, -1 An exception occured (IO)
# Index		0 = Success, -1 An exception occured (IO/SolrServerException)
# Dedup		0 = Success, -1 An exception occured (IO/SolrServerException)
# Clean		0 = Success, -1 An exception occured (IO/SolrServerException)
do_crawl() {
    . $1
    if [ $? -eq 0 ] ; then
	CRAWL_SUCCESSFUL=TRUE
    else
	CRAWL_SUCCESSFUL=FALSE
    fi
}

backup_current() {
    rm -r ../index_backups/$index_name/crawl
    mkdir -p ../index_backups/$index_name
    cp -r crawl ../index_backups/$index_name
}

recover_backup() {
    rm -r crawl
    cp -r ../index_backups/$index_name/crawl ./
}

if grep -qs IN_PROGRESS status ; then
    # Check if power failure or something like that has happened. Since the
    # copy operations should be fairly fast, it is reasonable safe to assume
    # that the presence of a Cygwin spawned java process means that a crawl is 
    # _actually_ happening. Not very safe.
    if `ps -a | grep -q java` ; then exit ; fi
    # Something has crashed, try to start again
    echo BROKEN > status
fi

if ! sanity_check ; then echo "Network unavailable" ; exit ; fi

if grep -qs COMPLETE status || [ ! -e status ] ; then
    echo IN_PROGRESS > status
    
    backup_current
    do_crawl $1

    update_status
    exit
fi

if grep -qs BROKEN status ; then
    echo IN_PROGRESS > status

    recover_backup
    do_crawl $1

    update_status
    exit
fi

