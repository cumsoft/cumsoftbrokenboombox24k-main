<?php
// Using the GET method:

// Check the GET header was set and is not empty
if(isset($_GET["run"]) && !empty($_GET["run"]))
{
    // You are free to add multiple cases here...
    switch($_GET["run"])
    {
        // So this could match: index.php?run=1
        case 1:
            
            // Then you can use shell_exec to run the .py file like so:
            $command = escapeshellcmd('/usr/custom/test.py');
            $output = shell_exec($command);
            
        break;
    }
}

// Using the POST method:

// Same sort of thing really, just uses post in the if statment to check.
// This will refresh the page though in order to get the PHP code to run...
if(isset($_POST["run"]) && !empty($_POST["run"]))
{
    // Same code above will go here...
}

// But to perform a POST request, check the notes section on the right:

// <form action="/action_page.php" method="get">
//  <input type="submit" value="Button 1">
//</form> 

// hxxps://codeclippet[dot]com/b39pdOwn


// <form action="/action_page.php" method="post">
//  <input type="submit" value="Button 2">
//</form> 
