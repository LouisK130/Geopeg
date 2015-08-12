<?php
	
	# AWS required files for working with S3
	
	require "aws/aws-autoloader.php";
	use Aws\S3\S3Client;
	
	# Some helper functions
	
	require "geopeg_util.php";
    require "geopeg_config.php";
	
	# We need a token, username, s3path
	
	$token = Geopeg_RequirePOST("token");
	$username = strtolower(Geopeg_RequirePOST("username"));
	$s3_path = strtolower(Geopeg_RequirePOST("s3path"));
	
	# Make sure the token is good for this user
	
	$geopeg_id = Geopeg_IsValidToken($username, $token);
	
	if(!$geopeg_id) {
		
		Geopeg_EchoResult("Failure", "Invalid token");
		die();
		
	}
	
	# We're good to go, now we need
	# To check that the claimed S3 upload actually occurred
	
	try {
	
		$S3_Client = S3Client::factory(array(
			'key' => $geopeg_aws_key,
			'secret' => $geopeg_aws_secret,
			'region' => 'us-east-1',
		));
		
		# Is it in the S3 bucket?
		
		$exists = $S3_Client->doesObjectExist("geopegbucket", $s3_path, array());
		
		
		if($exists) {
		
			Geopeg_EchoResult("Failure", "File still exists in S3");
			die();
		
		}
	
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error checking S3 storage for file");
		die();
		
	}
	
	# It doesn't exist, so now we delete from the db
	
	try{
		
		# Let's get a DB connection from the geopeg_util function
	
		$conn = Geopeg_GetMongoConn();
		$collection = $conn->selectCollection("geopegs");
		
		$collection->remove(array('s3path' => $s3_path));
	
	}
	catch(Exception $e) {
		
		# This will also happen if the metadata doesn't exist
		
		Geopeg_EchoResult("Failure", "Error deleting geopeg from database");
		die();
		
	}
	
	# We did it boys!111!!11
	
	Geopeg_EchoResult("Success", "File was deleted or did not exist.");
?>