require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140917205347_fix_incorrect_attachment_file_state.rb'

describe 'DataFixup::FixIncorrectAttachmentFileState' do
  it "should change 'active' files to 'available'" do
    file1 = attachment_model file_state: 'active'
    file2 = attachment_model file_state: 'deleted'
    FixIncorrectAttachmentFileState.up
    file1.reload.file_state.should == 'available'
    file2.reload.file_state.should == 'deleted'
  end
end
