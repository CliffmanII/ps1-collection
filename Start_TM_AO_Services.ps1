#list of Trend Micro and Apex One Services
$ServiceNames = 'ntrtscan', 'TMBMServer', 'TmCCSF', 'tmlisten', 'TmPfw', 'TmWSCSvc', 'AOTAgentSvc', 'DSASvc', 'Trend Micro Endpoint Basecamp', 'Trend Micro Web Service Communicator'

#parse through each service, and attempt to start it if it is not started
foreach ($Service in $ServiceNames) {
	$arrService = Get-Service -Name $Service
	while ($arrService.Status -ne 'Running') {
		Start-Service $ServiceName
		$arrService.Refresh()
	}
}