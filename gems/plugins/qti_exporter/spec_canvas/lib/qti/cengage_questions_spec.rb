require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting a cengage QTI" do

  it "should get the question bank name and id" do
    qti_data = file_as_string(cengage_question_dir, 'question_with_bank.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data)
    expect(hash[:question_bank_name]).to eq 'Practice Test Chapter 2'
    expect(hash[:question_bank_id]).to eq 'res00013'
  end

  it "should point a group to a question bank" do
    manifest_node=get_manifest_node('group_to_bank', :quiz_type => 'examination')
    a = Qti::AssessmentTestConverter.new(manifest_node, cengage_question_dir)
    a.create_instructure_quiz
    group = a.quiz[:questions].first
    expect(group[:pick_count]).to eq 20
    expect(group[:question_bank_migration_id]).to eq 'res00013'
  end

end
end
