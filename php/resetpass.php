<?php

	# Some settings for comparing dates

	date_default_timezone_set("America/New_York");
	
	# The library we use to hash/verify temporary passwords
	
	require_once "password_compat-master/lib/password.php";
	
	# Some helper functions
	
	require_once "geopeg_util.php";
	
	# We need a recovery token, email, and new pass
	
	$recovery_token = Geopeg_RequirePOST("recovery_token");
	$email = strtolower(Geopeg_RequirePOST("email"));
	$new_pass = Geopeg_RequirePOST("new_pass");
	
	# Let's get a DB conn
	
	$conn = Geopeg_GetMongoConn();
	$collection = $conn->selectCollection("users");
	
	# See if email's good and get the token/time if so
	
	try {
		
		$user_info = $collection->findOne(array("email" => $email));
		
		if(!$user_info) {
			
			Geopeg_EchoResult("Failure", "Invalid token");
			die();
			
		}
		
		if(!$user_info["forgot_token"] || !$user_info["forgot_time"]) {
			
			Geopeg_EchoResult("Failure", "Invalid token");
			die();
		
		}
		
		$hashed_token = $user_info["forgot_token"];
		
		# The token given matches hashed in database?
	
		if(!(password_verify($recovery_token, $hashed_token))) {
		
			Geopeg_EchoResult("Failure", "Invalid token");
			die();
	
		}
		
		# Compare dates to make sure it's within a day of issued time
		
		$issued_time = new DateTime($user_info["forgot_time"]);
		
		if(!$issued_time) {
		
			Geopeg_EchoResult("Failure", "Error parsing timestamp");
			die();
		
		}
		
		
		$issued_time_comparison = $issued_time->add(new DateInterval('P1D'));
		
		if(!$issued_time_comparison) {
			
			Geopeg_EchoResult("Failure", "Error parsing timestamp");
			die();
			
		}
		
		if($issued_time_comparison < new DateTime("now")) {
		
			Geopeg_EchoResult("Failure", "Token expired");
			
			# Clear token and expiration storage since it's useless
			
			$collection->update(array("_id" => $user_info['_id']), array(
				'$unset' => array(
					"forgot_token" => "",
					"forgot_time" => "",
				))
			);
			
			die();
	
		}
		
		# Hash the user-given new password.
		
		$hash = password_hash($new_pass, PASSWORD_BCRYPT);
		
		# Error hashing?
		
		if($hash == false) {
			
			Geopeg_EchoResult("Failure", "Error hashing password");
			die();
			
		}
		
		$collection->update(array("_id" => $user_info['_id']), array(
			'$set' => array(
				"password" => $hash
			),
			'$unset' => array(
				"forgot_token" => "",
				"forgot_time" => ""
			))
		);
		
		Geopeg_EchoResult("Success", "Password updated");
		
	}
	
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error changing password");
		die();
	
	}
	
?>