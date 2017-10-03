describe command('/bin/hab sup -h') do
  its(:stdout) { should match(/The Habitat Supervisor/) }
end

describe file('/hab/sup/default/data/services.dat') do
  it { should exist }
  its(:content) { should match('[]') }
end

describe service('hab-sup-default') do
  it { should be_running }
end
