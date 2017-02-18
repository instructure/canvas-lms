require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'assignment_resubmitted' do
  before :once do
    submission_model
  end

  let(:asset) { @submission }
  let(:notification_name) { :assignment_resubmitted }

  include_examples "a message"
end