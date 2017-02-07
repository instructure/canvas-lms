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

  it "should get answers correctly even when people write gross xml" do
    file_path = File.join(BASE_FIXTURE_DIR, 'qti')
    manifest_node=get_manifest_node('terrible_qti')
    hash = Qti::ChoiceInteraction.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>file_path)

    expect(hash[:answers].map{|a| a[:text]}).to match_array(['True', 'False', 'Not Sure'])
    expect(hash[:question_text]).to_not include("Not Sure")
  end
end
end
