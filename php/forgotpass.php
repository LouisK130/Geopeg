<?php
	
	# The library we use to hash/verify temporary passwords
	
	require_once "password_compat-master/lib/password.php";
	
	# Some helper functions
	
	require_once "geopeg_util.php";
	
	# We need an email
	
	$email = strtolower(Geopeg_RequirePOST("email"));
	
	# Lets get a DB conn
	
	$conn = Geopeg_GetMongoConn();
	$collection = $conn->selectCollection('users');
	
	# See if email's good
	
	try {
		
		$found = $collection->findOne(array("email" => $email));
	
		if(!$found) {
		
			# Email isn't valid, but we don't tell them that.
		
			Geopeg_EchoResult("Success", "Email sent");
			die();
			
		}
		
	}
	
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error searching database for user");
		die();
		
	}
	
	# Make a recovery password, store it hashed
	
	$temp_pass = bin2hex(openssl_random_pseudo_bytes(16));
	$hashed_temp_pass = password_hash($temp_pass, PASSWORD_BCRYPT);
	
	# Format a timestamp
	
	date_default_timezone_set("America/New_York");
	$issued_time = date("Y-m-d H:i:s");
	
	try {
		
		$collection->update(array("_id" => $found['_id']), array(
			'$set' => array(
				"forgot_token" => $hashed_temp_pass,
				"forgot_time" => $issued_time
			))
		);
		
	}
	catch(Exception $e) {
		
		Geopeg_EchoResult("Failure", "Error updating recovery information in database");
		die();
		
	}
	
	// PAY ATTENTION HERE
	// THIS TOKEN CAN'T GET ECHO'D HERE, IT NEEDS TO BE EMAILED
	// THIS IS TEMPORARY AND MUST NOT BE IGNORED!!
	
	// echo $temp_pass;
	
	Geopeg_EchoResult("Success", "Email sent", array());
	
	/*$message = "Greetings from Geopeg,\n\n
		A password reset was requested for your account. If you did not request this, you may ignore this email.\n
		If you did request it, the following is your recovery code.\n\n
		<html>
		<bold>" . $temp_pass . "</bold>
		</html>\n\n
		Please paste this code into the app.
	";
	
	$headers = 'MIME-Version: 1.0\r\n';
	$headers .= 'Content-type: text/html; charset=iso8859-1\r\n';
	$headers .= 'From: Geopeg App <admin@geopegapp.com>\r\n';
	$headers .= 'X-Mailer: PHP/' . phpversion() . '\r\n';
	
	# Send the mail
	
	mail($email, "Geopeg Password Recovery", $message, 'From: Geopeg <admin@geopegapp.com>\r\n');*/
	
?>