<?php
    
    require_once "geopeg_config.php";

	function Geopeg_EchoResult($result, $message, $extras = array()) {
		
		# An array of our information
		$json = array(
			'Result' => $result,
			'Message' => $message,
		);
			
			# Add extras
			
		foreach($extras as $key => $value) {
			$json[$key] = $value;
		}
		
		# Print it real nice and purty, like that mouth
		echo json_encode($json, JSON_PRETTY_PRINT);
		
	}
	
	# Other files use this to require_once that a given POST
	# element be present to continue
	# Returns:
	# The element on success
	# Null on failure
	
	function Geopeg_RequirePOST($element) {
		
		if(!isset($_POST[$element])) {
		
			Geopeg_EchoResult("Failure", "No " . $element . " given");
			die();
		
		}
		
		return filter_input(INPUT_POST, $element);
		
	}

	# Use this to get a connection to the MongoDB server(s)
	# Returns:
	# Connection on success
	# Null on error
	
	function Geopeg_GetMongoConn() {
        
        global $mongo_server, $mongo_username, $mongo_pass;
		
		try {
		
			$conn = new MongoClient($mongo_server, array("username" => $mongo_username, "password" => $mongo_pass));
			$db = $conn->selectDB("geopeg");
		
			return $db;
			
		}
		catch(Exception $e) {
			
			Geopeg_EchoResult("Failure", "Internal error. Please retry later.");
			die();
			return;
			
		}
	
	}
	
	# This function verifies that a given token
	# matches a username in the Geopeg database
	
	# Returns:
	# Client id if valid
	# False if invalid
	# Null if error
	
	function Geopeg_IsValidToken($username, $token) {
		
		$conn = Geopeg_GetMongoConn();
		
		if(!$conn) {
			
			return;
			
		}
		
		try {
			
			$collection = $conn->selectCollection("users");
			
			$userid_for_token = $collection->findOne(array('g_token' => $token, 'username' => $username), array('_id'));
			
			if(!$userid_for_token) {
				
				return false;
			
			}
				
			return $userid_for_token['_id']->__toString();
			
		}
		
		catch(Exception $e) {
			
			return;
		
		}
		
	}
	
?>