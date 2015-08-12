<?php
	
	# The library we use to hash/verify passwords
	
	require "password_compat-master/lib/password.php";
	
	# Some helper functions
	
	require "geopeg_util.php";
	
	# We need a username, password, and email
	
	$username = strtolower(Geopeg_RequirePOST("username"));
	$password = Geopeg_RequirePOST("password");
	$email = strtolower(Geopeg_RequirePOST("email"));
	
	# Hash the user-given password.
	
	$hash = password_hash($password, PASSWORD_BCRYPT);

	# Error hashing?
	
	if($hash == false) {
		
		Geopeg_EchoResult("Failure", "Error hashing password");
		die();
		
	}
	
	# Add the user to the database
	
	$conn = Geopeg_GetMongoConn();
	$collection = $conn->selectCollection("users");
	
	try {
		
		# Make sure the email is available
		
		$found = $collection->findOne(array("email" => $email));
		
		if($found) {
			
			Geopeg_EchoResult("Failure", "Email already in use.");
			die();
			
		}
		
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error checking email duplicity");
		die();
		
	}
	
	try {
		
		# See if username is already in use
		
		$found = $collection->findOne(array("username" => $username));
		
		if($found) {
			
			Geopeg_EchoResult("Failure", "Username already in use.");
			die();
			
		}
		
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error checking username duplicity");
		die();
		
	}
	
	# Try to add new user
	
	try {
		
		# MongoDB will automagically make the _id field a unique value for us
		
		$document = array(
			"username" => $username,
			"password" => $hash,
			"email" => $email,
		);
		
		$collection->insert($document);
	
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error inserting new user");
		die();
		
	}
	
	# We did it boys!111!!11
	
	Geopeg_EchoResult("Success", "Registered");
?>