<?php
	
	# Some helper functions
	
	require_once "geopeg_util.php";
	
	# We need a token and username
	
	$token = Geopeg_RequirePOST("token");
	$username = Geopeg_RequirePOST("username");
	
	# Custom start date?
	
	date_default_timezone_set("America/New_York");
	$start_date = date("Y-m-d H:i:s");
	
	if(isset($_POST["startdate"])) {
		
		# Make sure it's in a valid date format
		
		$date = filter_input(INPUT_POST, "startdate");
		if(DateTime::createFromFormat('Y-m-d H:i:s', $date) != false) {
			$start_date = $date;
		}
		
	}
	
	# Verify token and get user ID
	
	$geopeg_id = Geopeg_IsValidToken($username, $token);
	
	if(!$geopeg_id) {
			
		Geopeg_EchoResult("Failure", "Invalid token");
		die();
		
	}
	
	# We're good to go, now we need
	# to get the information from the db
	
	$results = array();
	
	# For each result, we create a table of the information
	# Then store in the above table
	
	try {
		
			
		# Let's get a DB connection from the geopeg_util function
	
		$conn = Geopeg_GetMongoConn();
		$collection = $conn->selectCollection("geopegs");
		
		# The first 10 pegs from this user that
		# are older than start_date
		
		$result_cursor = $collection->find(array(
			"posterid" => $geopeg_id,
			"datetime" => array('$lt' => $start_date),
		));
		
		$result_cursor->limit(10);
		$result_cursor->sort(array("datetime" => -1));
		
		foreach($result_cursor as $doc) {
		
			$easting_str = $doc["easting"];
			$northing_str = $doc["northing"];
			
			do {
				
				$easting_str = "0" . $easting_str;
				
			} while(strlen($easting_str) < 5);
			
			do {
				
				$northing_str = "0" . $northing_str;
				
			} while(strlen($northing_str) < 5);
			
			$result = array(
				"Location" => $doc['gzd'] . $easting_str . $northing_str,
				"Poster" => $doc['posterid'],
				"Time" => $doc['datetime'],
				"S3Path" => $doc['s3path'],
			);
			
			if(isset($doc['caption'])) {
				
				$result['Caption'] = $doc['caption'];
				
			}
			
			array_push($results, $result);
		
		}
	
		
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error selecting geopegs from database");
		die();
		
	}
	
	# We did it boys!111!!11
	# Make it a little prettier
	$return_array = array();
	$return_array["Results"] = $results;
	
	Geopeg_EchoResult("Success", "Metadata retrieved", $return_array);
	
?>