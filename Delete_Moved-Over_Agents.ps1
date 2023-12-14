# Define Functions

Function Resolve-Error($ErrorRecord=$Error[0]) {
    $ErrorRecord | Format-List * -Force
    $ErrorRecord.InvocationInfo | Format-List *
    $Exception = $ErrorRecord.Exception
    For ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) {
        "$i" * 80
        $Exception | Format-List * -Force
    }
}

Function Connect-mySQL([string]$user,[string]$pass,[string]$mySQLHost,[string]$database) {
    [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")

    $connStr = "server=" + $mySQLHost + ";port=3306;uid=" + $user + ";pwd=" + $pass + ";database=" + $database + ";Pooling=FALSE"
    $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
    $conn.Open()
    return $conn
}

Function Disconnect-MySQL($conn) {
    $conn.Close()
}

Function MySQLNonQuery($conn, $query) {
    $command = $conn.CreateCommand()
    $command.CommandText = $query
    $rows = $command.ExecuteNonQuery()
    $command.Dispose()
    If ($rowsUpdated) {
        return $rowUpdated
    }
    Else {
        return $false
    }
}

Function MySQLQuery($conn, [string]$query) {
    $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $conn)
    $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)
    $dataSet = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet, "data")
    $cmd.Dispose()
    return $dataSet.Tables["data"]
}

# Declare Variables

$u = 'user'
$p = 'password'
$db = 'labtech'
$host1 = 'oldServer'
$host2 = 'newServer'

$conn1 = Connect-MySQL $u $p $host1 $db
$conn2 = Connect-MySQL $u $p $host2 $db

$query = "SELECT c.Name AS ``Client``, a.Name AS ``Computer``, a.ComputerID AS ``ComputerID``, a.ClientID AS ``ClientID``, a.LocationID AS ``LocationID`` FROM computers a LEFT JOIN clients c ON a.ClientID = c.ClientID ORDER BY c.Name, a.Name"

$oldAgents = MySQLQuery $conn1 $query
$newAgents = MySQLQuery $conn2 $query

$IDs = @() # array to store the IDs that will be excluded

# Define LocationID Hash Table

$locTABLE = @{
    13  = '11'
    82  = '12'
    24  = '13'
    118 = '15'
    69  = '14'
    54  = '16'
    93  = '17'
    103 = '18'
    109 = '19'
    23  = '21'
    22  = '20'
    20  = '22'
    98  = '23'
    78  = '4'
    115 = '24'
    110 = '25'
    29  = '26'
    77  = '27'
    111 = '28'
    30  = '29'
    80  = '31'
    26  = '30'
    85  = '32'
    97  = '34'
    31  = '33'
    17  = '35'
    32  = '36'
    106 = '37'
    3   = '38'
    53  = '39'
    60  = '40'
    63  = '41'
    49  = '42'
    73  = '43'
    71  = '44'
    112 = '45'
    14  = '46'
    33  = '47'
    62  = '48'
    1   = '1'
    2   = '2'
    86  = '3'
    51  = '50'
    50  = '49'
    34  = '51'
    55  = '52'
    122 = '56'
    123 = '53'
    124 = '54'
    125 = '55'
    52  = '57'
    107 = '6'
    65  = '7'
    101 = '8'
    64  = '5'
    66  = '9'
    67  = '10'
    75  = '59'
    74  = '60'
    8   = '61'
    119 = '58'
    116 = '62'
    100 = '64'
    38  = '63'
    99  = '65'
    126 = '66'
    127 = '67'
    6   = '68'
    108 = '70'
    36  = '69'
    37  = '71'
    46  = '72'
    105 = '74'
    102 = '73'
    104 = '75'
    92  = '76'
    94  = '77'
    121 = '79'
    120 = '78'
    15  = '80'
    96  = '81'
}

# Loop Through the Location IDs on the Old Server
# Compare the Computer Names with those in the Matching
# Locations on the New Server

ForEach ($key in $locTable.keys) {
    $old = $oldAgents | Where {$_.LocationID -eq $key}
    $new = $newAgents | Where {$_.LocationID -eq $locTable[$key]}
    
    $missing = $old | Where {$new.Computer -notcontains $_.Computer}
    $missing | FT # to output the results for verification, etc.
    $IDs += $missing.ComputerID
}

# Create the Excluded IDs String

$exclude = $($IDs | Sort-Unique) -Join "','"
$exclude = "'" + "$($exclude)" + "'"
$exclude # to output the exclusions for verification, etc.

# Get all the Agent IDs, subtract the Excluded IDs
# Should be left with all the IDs of Agents that need to be deleted

$query2 = "SELECT computerID FROM computers WHERE computerID NOT IN ($($exclude))"

$delete = MySQLQuery $conn1 $query2

# For Each ID that needs to be deleted, delete it.

ForEach ($d in $delete) {
    $dQuery = "call sp_Delete($($d),'Computer has been Retired.')"
    
    MySQLQuery $conn1 $dQuery
}
