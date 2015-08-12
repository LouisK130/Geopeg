<?php
	
	# Some helper functions
	
	require "geopeg_util.php";
	
	# We need a username and token to begin with
	
	$username = strtolower(Geopeg_RequirePOST("username"));
	$token = Geopeg_RequirePOST("token");
	
	# Get a DB connection
	
	$conn = Geopeg_GetMongoConn();
	$collection = $conn->selectCollection("users");
		
	# If token matches username
		
	$userid = Geopeg_IsValidToken($username, $token);
	
	if($userid) {
		
		# Clear it
		# Client will also delete any local token storage,
		# So they will have to manually log back in later.
		
		try {
			
			$collection->update(array("username" => $username), array(
				'$unset' => array(
					"g_token" => ""
				))
			);
			
		}
		catch(Exception $e) {
			
			Geopeg_EchoResult("Failure", "Error logging out");
			die();
			
		}
		
		Geopeg_EchoResult("Success", "Logged out");
		die();
		
	}
	
	else {
			
		Geopeg_EchoResult("Failure", "Invalid token");
		die();
		
	}
?>