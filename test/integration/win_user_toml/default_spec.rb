describe file('C:\habitat\hab.exe') do
  it { should exist }
end

# splunkforwarder_content = <<-EOF
# [directories]
# path = ["C:/hab/pkgs/.../*.log"]
# EOF

describe file('c:\hab\user\splunkforwarder\config\user.toml') do
  it { should exist }
  its('content') { should match '[directories]\r\npath = ["C:/hab/pkgs/.../*.log"]' }
end
