require 'spec_helper'

# rsync package should be installed
describe package( 'rsync' ) do
  it { should be_installed }
end
