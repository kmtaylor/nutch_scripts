steps=3
echo "----- Index (Step 1 of $steps) -----"
$NUTCH_HOME/bin/nutch solrindex $SOLR_URL crawl/crawldb crawl/linkdb \
	crawl/segments/*

echo "----- Dedup (Step 2 of $steps) -----"
$NUTCH_HOME/bin/nutch solrdedup $SOLR_URL

echo "----- Clean (Step 3 of $steps) -----"
$NUTCH_HOME/bin/nutch solrclean crawl/crawldb $SOLR_URL

echo "runbot: FINISHED: Crawl completed!"
echo ""
