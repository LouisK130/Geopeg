<?php
	
	# AWS required files for working with S3
	
	require "aws/aws-autoloader.php";
	use Aws\S3\S3Client;
	
	# Some helper functions
	
	require "geopeg_util.php";
    require "geopeg_config.php";
	
	# We need a token, username, s3path, mgrsid
	
	$token = Geopeg_RequirePOST("token");
	$username = strtolower(Geopeg_RequirePOST("username"));
	$s3_path = strtolower(Geopeg_RequirePOST("s3path"));
	$mgrsid = strtolower(Geopeg_RequirePOST("mgrsid"));
	
	# If caption exists, use it
	
	if(isset($_POST['caption'])) {
			
		$caption = filter_input(INPUT_POST, "caption");
		
	}
	
	# Make sure the token is good for this user
	# If user_id is false, it's ignored
	
	$geopeg_id = Geopeg_IsValidToken($username, $token);
	
	if(!$geopeg_id) {
		
		Geopeg_EchoResult("Failure", "Invalid token", array());
		die();
		
	}
	
	# We're good to go, now we need
	# To check that the claimed S3 upload actually occurred
	
	# Search for the file in this user's "folder" only
	
	$actual_s3_path = $geopeg_id .. "/" .. $s3_path;
	
	try {
	
		$S3_Client = S3Client::factory(array(
            'key' => $geopeg_aws_key,
			'secret' => $geopeg_aws_secret,
			'region' => 'us-east-1',
		));
		
		# Is it in the S3 bucket?
		
		$exists = $S3_Client->doesObjectExist("geopegbucket", $actual_s3_path, array());
		
		
		if(!$exists) {
		
			Geopeg_EchoResult("Failure", "File does not exist in S3");
			die();
		
		}
	
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error checking S3 storage for file");
		die();
		
	}
	
	# Some date stuff, make a "now" timestamp
	
	date_default_timezone_set("America/New_York");
	$now = date("Y-m-d H:i:s");
	
	# It exists, so now we can put some metadata
	# for it, into the database
	
	try{
		
		# Let's get a DB connection from the geopeg_util function
	
		$conn = Geopeg_GetMongoConn();
		$collection = $conn->selectCollection("geopegs");
		
		$insertArray = array(
			"s3path" => $s3_path,
			"posterid" => $geopeg_id,
			"gzd" => substr($mgrsid, 0, 5),
			"easting" => (int)substr($mgrsid, 5, 5),
			"northing" => (int)substr($mgrsid, 10, 5),
			"datetime" => $now,
		);
		
		if(!empty($caption)) {
			
			$insertArray["caption"] = $caption;
			
		}
		
		$collection->insert($insertArray);
	
	}
	catch(MongoDuplicateKeyException $e) {
		
		Geopeg_EchoResult("Failure", "Entry already exists in database. Delete the current one and retry.");
		die();
		
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error inserting Geopeg into database.");
		die();
		
	}
	
	# We did it boys!111!!11
	
	Geopeg_EchoResult("Success", "Uploaded");
?>