require File.dirname(__FILE__) + '/../../qti_helper'

describe "Converting a respondus QTI" do
  it "should convert multiple choice" do
    manifest_node=get_manifest_node('multiple_choice')
    hash = Qti::ChoiceInteraction.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>d2l_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    hash.should == D2LExpected::MULTIPLE_CHOICE
  end

  it "should convert true false" do
    manifest_node=get_manifest_node('true_false')
    hash = Qti::ChoiceInteraction.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>d2l_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    hash.should == D2LExpected::TRUE_FALSE
  end

#  it "should convert the assessment into a quiz" do
#    manifest_node=get_manifest_node('assessment', nil, 'Test')
#    a = Qti::AssessmentTestConverter.new(manifest_node, d2l_question_dir, false)
#    a.create_instructure_quiz
#    pp a.quiz
#    a.quiz.should == D2LExpected::ASSESSMENT
#  end


end

module D2LExpected
  MULTIPLE_CHOICE =
          {:correct_comments=>"Good work",
                  :incorrect_comments=>"Good work",
                  :answers=>
                          [{:weight=>100,
                                   :migration_id=>"QUES_32399_53455_A1013651",
                                   :text=>"True",
                                   :comments=>"Good work"},
                           {:weight=>0,
                                   :migration_id=>"QUES_32399_53455_A1013652",
                                   :text=>"False",
                                   :comments=>"That's not correct"}],
                  :question_type=>"multiple_choice_question",
                  :migration_id=>"d2l_multiple_choice",
                  :points_possible=>1,
                  :question_text=>
                          "<!--BBQ-001-->Akkadian is a Semitic language, related to Hebrew and Arabic.",
                  :question_name=>""}
  TRUE_FALSE =
          {:question_type=>"multiple_choice_question",
                  :correct_comments=>"",
                  :points_possible=>1,
                  :answers=>
                          [{:text=>"True",
                                   :weight=>100,
                                   :migration_id=>"QUES_443669_562987_A2890736",
                                   :comments=>""},
                           {:text=>"False",
                                   :weight=>0,
                                   :migration_id=>"QUES_443669_562987_A2890737",
                                   :comments=>""}],
                  :incorrect_comments=>"",
                  :question_text=>"I have submitted the Week 2 Storybook assignment.",
                  :question_name=>"",
                  :migration_id=>"d2l_true_false"}
end
