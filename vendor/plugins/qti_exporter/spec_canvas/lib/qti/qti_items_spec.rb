require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting QTI items" do
  it "should convert an item with empty leading <div />" do
    file_path = File.join(BASE_FIXTURE_DIR, 'qti')
    question  = get_question_hash(file_path, 'zero_point_mc')

    question[:question_text].should == "<div class=\"text\"></div>\n<br/>\nMC - multiple correct with multiple selection. C and D are correct"
  end

  it "should sanitize InstructureMetadata" do
    file_path = File.join(BASE_FIXTURE_DIR, 'qti')
    question = get_question_hash(file_path, 'sanitize_metadata')
    question[:question_bank_name].should eql 'Sad & Broken'
    question[:question_text].should_not =~ /divp/
  end
end
end
