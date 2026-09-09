param([string]$BaseUrl = 'http://localhost:5000')
$ErrorActionPreference = 'Stop'

function Assert-Status($Response, [int]$Expected) {
    if ([int]$Response.StatusCode -ne $Expected) {
        throw "Expected HTTP $Expected, received $($Response.StatusCode)"
    }
}

Assert-Status (Invoke-WebRequest "$BaseUrl/health" -UseBasicParsing) 200
Assert-Status (Invoke-WebRequest "$BaseUrl/swagger/index.html" -UseBasicParsing) 200
$schema = Invoke-RestMethod "$BaseUrl/swagger/v1/swagger.json"
if (-not $schema.paths.'/api/tasks') { throw 'Task endpoints are missing from Swagger' }

$created = Invoke-WebRequest "$BaseUrl/api/tasks" -Method Post -ContentType 'application/json' -Body '{"title":"Smoke test","description":"Temporary verification task"}' -UseBasicParsing
Assert-Status $created 201
$task = $created.Content | ConvertFrom-Json
try {
    $read = Invoke-RestMethod "$BaseUrl/api/tasks/$($task.id)"
    if ($read.title -ne 'Smoke test') { throw 'Task read failed' }
    $all = Invoke-RestMethod "$BaseUrl/api/tasks"
    if ($task.id -notin @($all.id)) { throw 'Task list failed' }
    Assert-Status (Invoke-WebRequest "$BaseUrl/api/tasks/$($task.id)" -Method Put -ContentType 'application/json' -Body '{"title":"Smoke test updated","isCompleted":true}' -UseBasicParsing) 204
    $updated = Invoke-RestMethod "$BaseUrl/api/tasks/$($task.id)"
    if (-not $updated.isCompleted -or $updated.title -ne 'Smoke test updated') { throw 'Task update failed' }
} finally {
    Assert-Status (Invoke-WebRequest "$BaseUrl/api/tasks/$($task.id)" -Method Delete -UseBasicParsing) 204
}
try {
    Invoke-WebRequest "$BaseUrl/api/tasks/$($task.id)" -UseBasicParsing | Out-Null
    throw 'Deleted task still exists'
} catch {
    if ([int]$_.Exception.Response.StatusCode -ne 404) { throw }
}
try {
    Invoke-WebRequest "$BaseUrl/api/tasks" -Method Post -ContentType 'application/json' -Body '{"title":" "}' -UseBasicParsing | Out-Null
    throw 'Empty title was accepted'
} catch {
    if ([int]$_.Exception.Response.StatusCode -ne 400) { throw }
}
Write-Output 'PASS: health, Swagger, task create/list/read/update/delete, missing task, and title validation.'
