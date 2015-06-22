require 'spec_helper'

# rsync and xinetd packages should be installed
[ 'rsync', 'xinetd' ].each do |installed_package|
  describe package( installed_package ) do
    it { should be_installed }
  end
end

describe file( '/etc/xinetd.d/rsync' ) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:content) { should match /^\s*service\s+rsync$/ }
  its(:content) { should match /^\s*disable\s+=\s+no\s*$/ }
  its(:content) { should match /^\s*wait\s+=\s+no\s*$/ }
  its(:content) { should match /^\s*server\s+=\s+(.*)\/bin\/rsync\s*$/ }
  its(:content) { should match /^\s*server_args\s+=\s+--daemon\s*$/ }
  its(:content) { should match /^\s*socket_type\s+=\s+stream\s*$/ }
  its(:content) { should match /^\s*port\s+=\s+873\s*$/ }
  its(:content) { should match /^\s*protocol\s+=\s+tcp\s*$/ }
end

describe file( '/etc/rsyncd.conf' ) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 644 }
  its(:content) { should match /^\s*lock file\s+=\s+\/var\/run\/rsync\.lock/ }
  its(:content) { should match /^\s*log file\s+=\s+\/var\/log\/rsyncd\.log/ }
  its(:content) { should match /^\s*pid file\s+=\s+\/var\/run\/rsyncd\.pid/ }
  its(:content) { should match /^\s*\[kitchen\]/ }
  its(:content) { should match /^\s*path\s+=\s+\/tmp\/kitchen\// }
  its(:content) { should match /^\s*comment\s+=\s+test-kitchen/ }
  its(:content) { should match /^\s*uid\s+=\s+vagrant/ }
  its(:content) { should match /^\s*gid\s+=\s+vagrant/ }
  its(:content) { should match /^\s*read only\s+=\s+no/ }
  its(:content) { should match /^\s*list\s+=\s+yes/ }
  its(:content) { should match /^\s*auth users\s+=\s+vagrant,\s+kitchen/ }
  its(:content) { should match /^\s*secrets file\s+=\s+\/etc\/rsyncd\.secrets/ }
  its(:content) { should match /^\s*hosts allow\s+=\s+127\.0\.0\.1\/255\.255\.255\.0/ }
end

describe file( '/etc/rsyncd.secrets' ) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_mode 600 }
  its(:content) { should match /^\s*vagrant:vagrant$/ }
  its(:content) { should match /^\s*kitchen:kitchen$/ }
end

describe service( 'xinetd' ) do
  it { should be_enabled }
  it { should be_running }
end

# For each user we defined in rsync_daemon_user_secrets, test that we can login & list files from "kitchen" module/share
[ 'kitchen', 'vagrant' ].each do |rsync_user|
  describe command("RSYNC_PASSWORD='#{ rsync_user }'   rsync -rtv #{ rsync_user }@127.0.0.1::kitchen | grep -c 'sentinel-file'") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^1$/ }
  end
end

# Transfer the sentinel-file to /tmp/, and check that it contains what we expect
describe command("RSYNC_PASSWORD='vagrant'   rsync -rtv vagrant@127.0.0.1::kitchen/roles/*/test/integration/sentinel-file /tmp/") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /^sent \d+ bytes  received \d+ bytes  [0-9\.]+ bytes\/sec$/ }
  its(:stdout) { should match /^total size is \d+  speedup is [0-9\.]+$/ }
end

describe file( '/tmp/sentinel-file' ) do
  it { should be_file }
  its(:content) { should match /^# This file is for validating that the xinetd rsync service works$/ }
end