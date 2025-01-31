$count = 0
While ($count -le 12) {
	start-sleep 10
	shutdown -a | Out-null
	$count ++
}