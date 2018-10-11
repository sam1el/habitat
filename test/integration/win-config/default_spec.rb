describe file('C:\habitat\hab.exe') do
  it { should exist }
end

# This needs to be updated each time Habitat is released so we ensure we're getting the version
# required by this cookbook.
# TODO: Inspec session seems to not have the updated windows system path when run with 'kitchen test'
# Works fine if you run a converge and then a verify as two seperate commands
# For now, hitting hab.exe directly to avoid test failure
describe command('C:\habitat\hab.exe -V') do
  its('stdout') { should match(%r{^hab 0.65.0/}) }
  its('exit_status') { should eq 0 }
end

describe json('C:\hab\sup\default\data\census.dat') do
  scpath = ['census_groups', 'splunkforwarder.default', 'service_config']
  # Incarnation is just the current timestamp, so we can't compare to an exact
  # value. Instead just make sure it looks right.
  its(scpath + ['incarnation']) { should be > 1_500_000_000 }
  its(scpath + %w(value directories path)) { should eq ['C:/hab/pkgs/.../*.log'] }
end
