describe file('C:\habitat\hab.exe') do
  it { should exist }
end

servicecheck = <<-EOH
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer secret")
$uri = "http://localhost:9631/services/splunkforwarder/default"
$reply = (Invoke-RestMethod -Headers $headers -uri $uri).cfg | Convertto-Json
$reply
EOH

describe json(command: servicecheck) do
  its(%w(directories path)) { should eq ['C:/hab/pkgs/.../*.log'] }
end
