<?php
	
	# The library we use to hash and compare passwords
	
	require "password_compat-master/lib/password.php";
	
	# The needed files for AWS Cognito integration
	
	require "aws/aws-autoloader.php";
	use Aws\CognitoIdentity\CognitoIdentityClient;
	
	# Some helper functions
	
	require "geopeg_util.php";
    require "geopeg_config.php";
	
	# We need a username to begin with
	
	$username = strtolower(Geopeg_RequirePOST("username"));
	
	# Trying to refresh token
	
	if(isset($_POST['token'])) {
		
		# AWS Cognito tokens only last 15 minutes, and STS credentials an hour
		# This means that every hour at the most, users will have to make
		# A call to this script with their Geopeg Token, requesting new Cognito credentials
		
		$token = filter_input(INPUT_POST, "token");
		
		# They supplied a token, so we're just refreshing the AWS Token
		# This function returns the user id on success, false on invalid token, and null on error
		
		$geopeg_id = Geopeg_IsValidToken($username, $token);
		
		if($geopeg_id) {
			
			# This function will get and print geopeg token, AWS Id, AWS Token
			
			GetAWSToken($token, $geopeg_id);
			die();
			
			# I decided to use the user_id here instead of username
			# This id will be unchanging, and can be safely used to store
			# photos to an account "folder" in S3, unlike username which may change
			
		}
		else {
			
			# If they want to login manually,
			# they shouldn't send a token.
				
			Geopeg_EchoResult("Failure", "Invalid token");
			
		}
		
		die();
		
	}
	
	else {
		
		# No token, we need to verify a password here, not just a token
		# But to begin with, we atleast need a password...
		
		$password = Geopeg_RequirePOST("password");
		
		# Get a DB connection
	
		$conn = Geopeg_GetMongoConn();
		
		# Now we need to pull their info
		
		try {
			
			$collection = $conn->selectCollection("users");
			
			$user_result = $collection->findOne(array('username' => $username));
			
			
			if(!$user_result) {
				
				Geopeg_EchoResult("Failure", "Invalid username");
				die();
				
			}
			
		}
		catch(Exception $e) {
			
			Geopeg_EchoResult("Failure", "Error searching for user in database");
			die();
			
		}
		
		$hash_pw = $user_result['password'];
		
		# Is the password right?...
		
		if($hash_pw == null || !(password_verify($password, $hash_pw))) {
			
			# Aw.. No dice.
			Geopeg_EchoResult("Failure", "Invalid password");
			die();
			
		}
		
		# Username and password are good! Woo!
		# Generate them a token
	
		$token = bin2hex(openssl_random_pseudo_bytes(16));
		
		# Put it in the database
		
		try {
			
			# Get the document ID from last search so we don't have to do it again
			$doc_id = $user_result['_id']->__toString();
			
			$collection->update(array('_id' => $user_result['_id']), array('$set' => array("g_token" => $token)));

			
		}
		catch(Exception $e) {
			
			Geopeg_EchoResult("Failure", "Error updating token in database");
			die();
			
		}
		
		# We made it boys! Our end of verification is complete
		# Now we get them some AWS Cognito credentials
		
		# This function will get AWS credentials
		# and echo all info to user
		GetAWSToken($token, $user_result['_id']->__toString());
	}
	
	#######################################################
	# End main script
	#######################################################
	
	# Function declarations
	
	function GetAWSToken($token, $id) {
		
		try {
		
			# Create a new client object with access
			$cognitoClient = CognitoIdentityClient::factory(array(
				'key' => $geopeg_aws_key,
				'secret' => $geopeg_aws_secret,
				'region' => 'us-east-1',
			));
			
			# Get an AWS token for this username
			$token_result = $cognitoClient->getOpenIdTokenForDeveloperIdentity(array(
				'IdentityPoolId' => 'us-east-1:d7954a79-61f7-45aa-81ac-5d376864666b',
				'Logins' => array(
					'login.geopeg' => $id,
				),
			));
			
			# Extract information from the response object
			$AWSValues = array(
				"Geopeg_ID" => $id,
				"Geopeg_Token" => $token,
				"AWSId" => $token_result->get("IdentityId"),
				"AWSToken" => $token_result->get("Token"),
			);
			
			# Format it pretty and reply it to the user
			Geopeg_EchoResult("Success", "Logged in", $AWSValues);
		
		}
		catch(Exception $e) {
			
			echo $e;
			
			Geopeg_EchoResult("Failure", "Error getting AWS credentials");
			die();
			
		}
		
	}

?>