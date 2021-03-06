#!/bin/bash


# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_AUX=2
ERR_VOR=4
#export HOME=/tmp
# add a trap to exit gracefully
function cleanExit ()
{
local retval=$?
local msg=""
case "$retval" in
$SUCCESS) msg="Processing successfully concluded";;
$ERR_AUX) msg="Failed to retrieve reference to auxiliary data";;
$ERR_VOR) msg="Failed to retrieve reference to orbital data";;
*) msg="Unknown error";;
esac
[ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
exit $retval
}
trap cleanExit EXIT

# get the catalogue access point
cat_osd_root="`ciop-getparam aux_catalogue`"

function getAUXref() {
  local rdf=$1
  local ods=$2
  ciop-log "INFO" "rdf is $rdf"
  ciop-log "INFO" "ods is $ods" 
  startdate="`ciop-casmeta -f "ical:dtstart" $rdf | tr -d "Z"`"
  stopdate="`ciop-casmeta -f "ical:dtend" $rdf | tr -d "Z"`"
  ciop-log "INFO" "startdate is $startdate"
  ciop-log "INFO" "stopdate is $stopdate"
  ciop-log "INFO" "opensearch-client -f Rdf -p time:start=$startdate -p time:end=$stopdate $ods"

  opensearch-client -v -f Rdf -p "time:start=$startdate" -p "time:end=$stopdate" $ods
}



while read input
do
	ciop-log "INFO" "dealing with $input"
	
	for aux in ASA_CON_AX ASA_INS_AX ASA_XCA_AX ASA_XCH_AX
	do
		ciop-log "INFO" "Getting a reference to $aux"
		
		for url in `getAUXref $input $cat_osd_root/$aux/description`
		do
			ciop-log "INFO" "the url is $url"
 			#pass the aux reference to the next node
			[ "$url" != "" ] && echo "aux=$url" | ciop-publish -s || exit $ERR_AUX
		done
		
	done
	
	# DOR_VOR_AX
	ciop-log "INFO" "Getting a reference to DOR_VOR_AX"
	ref=`getAUXref $input $cat_osd_root/DOR_VOR_AX/description`
		
	#pass the aux reference to the next node
	[ "$ref" != "" ] && echo "vor=$ref" | ciop-publish -s || exit $ERR_VOR
		
	# pass the SAR reference to the next node
	echo "sar=$input" | ciop-publish -s
done
