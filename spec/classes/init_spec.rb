require 'spec_helper'
describe 'glusterfs' do
  context 'with default values for all parameters' do
    it { is_expected.to contain_class('glusterfs') }
  end
end
