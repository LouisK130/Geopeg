<?php
	
	# Some helper functions
	
	require_once "geopeg_util.php";
	
	# We need an MGRSID
	
	$mgrsid = strtolower(Geopeg_RequirePOST("mgrsid"));
	
	# Custom view size?
	# 1 = 10 x 10 meters
	# 1.5 = 50 x 50 meters
	# 2 = 100 x 100 meters
	# 3 = 1 x 1 kilometers
	
	$view_size = 1;
	
	if(isset($_POST["size"])) {
		$size = filter_input(INPUT_POST, "size");
		if(is_numeric($size)) {
			if($size > 3) {
				
				$size = 3; # 1x1 kilometers
				
			}
			if($size < 1) {
				
				$size = 1; # 10 x 10 meters
				
			}
			if(strpos($size, ".")) {
				
				$size = 1.5; # 50 x 50 meters
			
			}
			$view_size = $size;
		}
	}
	
	# Custom start date?
	
	date_default_timezone_set("America/New_York");
	$start_date = date("Y-m-d H:i:s");
	$invalid_date = false;
	
	if(isset($_POST["startdate"])) {
		
		# Make sure it's in a valid date format
		
		$date = filter_input(INPUT_POST, "startdate");
		if(DateTime::createFromFormat('Y-m-d H:i:s', $date) != false) {
			$start_date = filter_input(INPUT_POST, "startdate");
		}
		else {
			$invalid_date = true;
		}
		
	}
	
	# Let's get a DB connection from the geopeg_util function
	
	$conn = Geopeg_GetMongoConn();
	$collection = $conn->selectCollection("geopegs");
	
	# Define max and mins for size
	
	$gzd = substr($mgrsid, 0, 5);
	
	$easting = substr($mgrsid, 5, 5); # e.g. 12345
	$northing = substr($mgrsid, 10, 5); # e.g 67890
	
	# This method works for all sizes except 1.5
	# Because 1.5 is the only one that isn't a native precision level of MGRS
	
	if(!strpos($view_size, ".")) {
	
		$min_e = substr($easting, 0, 0 - $view_size); # Truncates 'size' number of characters from the end
		$max_e = $min_e + 1; # Exclusive when searching in database
	
		$min_n = substr($northing, 0, 0 - $view_size);
		$max_n = $min_n + 1;
	
		# Now we have to add back zeroes to make them
		# The right length of string for later use
	
		$x = 0;
		while($x < $view_size) {
		
			$min_e = $min_e . "0";
			$max_e = $max_e . "0";
			$min_n = $min_n . "0";
			$max_n = $max_n . "0";
		
			$x = $x + 1;
	
		}
	
	}
	else {
		
		if($view_size == 1.5) {
		
			# Size is 1.5, so we need to calculate more than just an MGRS precision level
			# Truncate these to 10x10 precision
		
			$easting = substr($easting, 0, 4) . "0";
			$northing = substr($northing, 0, 4) . "0";
		
			$min_e = $easting - 20;
			$max_e = $easting + 30;
			$min_n = $northing - 20;
			$max_n = $northing + 30;
			
		}
		else {
			
			# This should never happen since clamped it above, but who knows...
			Geopeg_EchoResult("Failure", "Invalid size specified");
			die();
			
		}
		
	
	}
	
	# We're good to go, now we need
	# to get the information from the db
	
	$results = array();
	
	try {
		
		$result_cursor = $collection->find(array(
			"gzd" => $gzd,
			"northing" => array('$gte' => (int)$min_n, '$lt' => (int)$max_n),
			"easting" => array('$gte' => (int)$min_e, '$lt' => (int)$max_e),
			"datetime" => array('$lt' => $start_date),
		));
		
		# Find the most recent 10 results, older than start_date
		
		$result_cursor->limit(10);
		$result_cursor->sort(array("datetime" => -1));
		
		foreach($result_cursor as $doc) {
			
			# Loop the results as put them in $results
			
			if(!$doc['gzd'] || !$doc['easting'] || !$doc['northing'] || !$doc['posterid'] || !$doc['datetime'] || !$doc['s3path']) {
				
				# Row is incomplete, skip it
				continue;
			
			}
			
			# Add back leading zeroes to preserve 15 char length
		
			$easting_str = $doc['easting'];
			$northing_str = $doc['northing'];
			
			while(strlen($easting_str) < 5) {
			
				$easting_str = "0" . $easting_str;
		
			}	
		
			while(strlen($northing_str) < 5) {
			
				$northing_str = "0" . $northing_str;
			
			}
			
			$result = array(
				"Location" => $doc['gzd'] . $easting_str . $northing_str,
				"Poster" => $doc['posterid'],
				"Time" => $doc['datetime'],
				"Caption" => "",
				"S3Path" => $doc['s3path'],
				"Geolocked" => false,
			);
			
					
			if(isset($doc['caption'])) {
			
				$result['Caption'] = $doc['caption'];
			
			}
		
			if(isset($doc['geolocked'])) {
			
				$result['Geolocked'] = $doc['geolocked'];
			
			}
			
			# This is to check for geolock
	
			$in_location = false;
	
			if(isset($_POST['user_mgrsid'])) {
		
				$u_mgrsid = filter_input(INPUT_POST, "user_mgrsid");
				$u_10m_e = substr($u_mgrsid, 5, 4);
				$u_10m_n = substr($u_mgrsid, 10, 4);
			
				if($u_10m_e == substr($easting_str, 0, 4) && $u_10m_n == substr($northing_str, 0, 4)) {
				
					$in_location = true;
				
				}
			
			}
			
			if($result['Geolocked'] && !$in_location) {
		
				$result["S3Path"] = "";
		
			}
			
			array_push($results, $result);
		
		}
		
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error fetching geopeg metadata");
		die();
		
	}
	# We did it boys!111!!11
	
	# Just to make it a little prettier
	$return_array = array();
	$return_array["Results"] = $results;
	
	Geopeg_EchoResult("Success", "Metadata retrieved", $return_array);
	
?>