# runbot script to run the Nutch bot for crawling and re-crawling.
# Usage: bin/runbot [safe]
#        If executed in 'safe' mode, it doesn't delete the temporary
#        directories generated during crawl. This might be helpful for
#        analysis and recovery in case a crawl fails.
#
# Author: Susam Pal

steps=7
echo "----- Inject (Step 1 of $steps) -----"
$NUTCH_HOME/bin/nutch inject crawl/crawldb urls

echo "----- Generate, Fetch, Parse, Update (Step 2 of $steps) -----"
for((i=0; i < $depth; i++))
do
  echo "--- Beginning crawl at depth `expr $i + 1` of $depth ---"
  $NUTCH_HOME/bin/nutch generate crawl/crawldb crawl/segments $topN \
      -adddays $adddays
  if [ $? -ne 0 ]
  then
    echo "runbot: Stopping at depth $depth. No more URLs to fetch."
    break
  fi
  segment=`ls -d crawl/segments/* | tail -1`

  $NUTCH_HOME/bin/nutch fetch $segment
  if [ $? -ne 0 ]
  then
    echo "runbot: fetch $segment at depth `expr $i + 1` failed."
    echo "runbot: Deleting segment $segment."
    rm $RMARGS $segment
    continue
  fi

  if [ $i -eq 0 -a $newLinks = true ] ; then
    do_newLinks=-newLinks
  else
    do_newLinks=
  fi
  $NUTCH_HOME/bin/nutch updatedb crawl/crawldb $segment $do_newLinks
  if [ $? -ne 0 ] ; then exit 1 ; fi

  if [ $adddays -ne 0 ] ; then adddays=0 ; fi
done

echo "----- Merge Segments (Step 3 of $steps) -----"
$NUTCH_HOME/bin/nutch mergesegs crawl/MERGEDsegments crawl/segments/*
if [ $? -ne 0 ] ; then exit 1 ; fi
if [ "$safe" != "yes" ]
then
  rm $RMARGS crawl/segments
else
  rm $RMARGS crawl/BACKUPsegments
  mv $MVARGS crawl/segments crawl/BACKUPsegments
fi

mv $MVARGS crawl/MERGEDsegments crawl/segments

echo "----- Invert Links (Step 4 of $steps) -----"
$NUTCH_HOME/bin/nutch invertlinks crawl/linkdb crawl/segments/*
if [ $? -ne 0 ] ; then exit 1 ; fi

echo "----- Index (Step 5 of $steps) -----"
$NUTCH_HOME/bin/nutch solrindex $SOLR_URL crawl/crawldb crawl/linkdb \
	crawl/segments/*
if [ $? -ne 0 ] ; then exit 1 ; fi

echo "----- Dedup (Step 6 of $steps) -----"
$NUTCH_HOME/bin/nutch solrdedup $SOLR_URL
if [ $? -ne 0 ] ; then exit 1 ; fi

echo "----- Clean (Step 7 of $steps) -----"
$NUTCH_HOME/bin/nutch solrclean crawl/crawldb $SOLR_URL
if [ $? -ne 0 ] ; then exit 1 ; fi

echo "runbot: FINISHED: Crawl completed!"
echo ""
