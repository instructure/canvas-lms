require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting QTI items" do
  it "should convert an item with empty leading <div />" do
    file_path = File.join(BASE_FIXTURE_DIR, 'qti')
    question  = get_question_hash(file_path, 'zero_point_mc')

    expect(question[:question_text]).to eq "<div class=\"text\"></div>\n<br/>\nMC - multiple correct with multiple selection. C and D are correct"
  end

  it "should sanitize InstructureMetadata" do
    file_path = File.join(BASE_FIXTURE_DIR, 'qti')
    question = get_question_hash(file_path, 'sanitize_metadata')
    expect(question[:question_bank_name]).to eql 'Sad & Broken'
    expect(question[:question_text]).not_to match /divp/
  end
end
end
