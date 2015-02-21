require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting Angel QTI" do

  it "should convert multiple_choice" do
    qti_data = file_as_string(angel_question_dir, 'p_multiple_choice.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'multiple_choice_question', :custom_type=>'angel')
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq AngelPropExpected::MULTIPLE_CHOICE
  end

  it "should convert multiple answer" do
    qti_data = file_as_string(angel_question_dir, 'p_multiple_answers.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'multiple_answers_question', :custom_type=>'angel')
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq AngelPropExpected::MULTIPLE_ANSWER
  end

  it "should convert true false" do
    qti_data = file_as_string(angel_question_dir, 'p_true_false.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'true_false_question', :custom_type=>'angel')
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq AngelPropExpected::TRUE_FALSE
  end

  it "should convert essay" do
    qti_data = file_as_string(angel_question_dir, 'p_essay.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'essay_question', :custom_type=>'angel')
    expect(hash).to eq AngelPropExpected::ESSAY
  end

  it "should convert short answer" do
    qti_data = file_as_string(angel_question_dir, 'p_short_answer.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'short_answer_question', :custom_type=>'angel')
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq AngelPropExpected::SHORT_ANSWER
  end

  it "should convert short answer with no correct answers into essay" do
    qti_data = file_as_string(angel_question_dir, 'p_short_answer_as_essay.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'short_answer_question', :custom_type=>'angel')
    expect(hash).to eq AngelPropExpected::SHORT_ANSWER_AS_ESSAY
  end

  it "should convert matching questions" do
    qti_data = file_as_string(angel_question_dir, 'p_matching.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'matching_question', :custom_type=>'angel')

    # make sure the ids are correctly referencing each other
    matches = []
    hash[:matches].each {|m| matches << m[:match_id]}
    hash[:answers].each do |a|
      expect(matches.include?(a[:match_id])).to be_truthy
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq AngelPropExpected::MATCHING
  end
  
  it "should convert ordering questions into matching questions" do
    qti_data = file_as_string(angel_question_dir, 'p_ordering.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'ordering_question', :custom_type=>'angel')
    matches = []
    hash[:matches].each {|m| matches << m[:match_id]}
    hash[:answers].each do |a|
      expect(matches.include?(a[:match_id])).to be_truthy
    end
    # compare everything without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq AngelPropExpected::ORDER
  end

  it "should convert file response questions" do
    qti_data = file_as_string(angel_question_dir, 'p_offline.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'file_upload_question', :custom_type=>'angel')
    expect(hash).to eq AngelPropExpected::FILE_RESPONSE
  end

  it "should convert fill in the blank questions" do
    qti_data = file_as_string(angel_question_dir, 'p_fib.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'fill_in_multiple_blanks_question', :custom_type=>'angel')
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq AngelPropExpected::FIB
  end

  it "should convert likert scale" do
    qti_data = file_as_string(angel_question_dir, 'p_likert_scale.xml')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'stupid_likert_scale_question', :custom_type=>'angel')
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq AngelPropExpected::LIKERT
  end

end

module AngelPropExpected
  TRUE_FALSE =
      {
          :incorrect_comments=>"",
          :question_type=>"multiple_choice_question",
          :migration_id=>"",
          :question_text=>"<div>This is annoying.</div>",
          :answers=>
              [{:text=>"True", :migration_id=>"ChoiceTrue", :weight=>100},
               {:text=>"False", :migration_id=>"ChoiceFalse", :weight=>0}],
          :question_name=>"Question for main question bank.",
          :points_possible=>1,
          :correct_comments=>""}

  MULTIPLE_CHOICE =
      {
          :incorrect_comments=>"",
          :question_type=>"multiple_choice_question",
          :migration_id=>"",
          :question_text=>"<div>What is an LMS</div>",
          :answers=>
              [{:text=>"Learning microsoft system",
                :migration_id=>"answerChoice1",
                :weight=>0},
               {:text=>"Listening management system",
                :migration_id=>"answerChoice2",
                :weight=>0},
               {:text=>"Liberal management system",
                :migration_id=>"answerChoice3",
                :weight=>0},
               {:text=>"learning management system",
                :migration_id=>"answerChoice4",
                :weight=>100}],
          :question_name=>"Multiple choice question title",
          :points_possible=>1,
          :correct_comments=>""}

  ESSAY =
      {
          :incorrect_comments=>"",
          :question_type=>"essay_question",
          :migration_id=>"",
          :question_text=>"<div>Rhode Island is neither a road nor an island. Discuss</div>",
          :answers=>[],
          :question_name=>"Essay question title here",
          :points_possible=>1,
          :correct_comments=>""}

  LIKERT =
      {
          :question_name=>"What is the best thingy",
          :incorrect_comments=>"",
          :points_possible=>1,
          :answers=>
              [{:weight=>100, :text=>"sucks", :migration_id=>"scale_0"},
               {:weight=>100, :text=>"decent", :migration_id=>"scale_1"},
               {:weight=>100,
                :text=>"wicked awesome",
                :migration_id=>"scale_2"}],
          :question_type=>"multiple_choice_question",
          :correct_comments=>"",
          :migration_id=>"",
          :question_text=>"<div>How good <em>is</em> Instructure</div>"}

  MULTIPLE_ANSWER =
      {
          :question_name=>"Multiple select",
          :answers=>
              [{:migration_id=>"answerChoice1", :text=>"a", :weight=>0, :comments=>"feedback - a"},
               {:migration_id=>"answerChoice2", :text=>"b", :weight=>100, :comments=>"feedback - b"},
               {:migration_id=>"answerChoice3", :text=>"c", :weight=>0, :comments=>"feedback - c"},
               {:migration_id=>"answerChoice4", :text=>"d", :weight=>0, :comments=>"feedback - d"},
               {:migration_id=>"answerChoice5", :text=>"e", :weight=>100}],
          :incorrect_comments=>"",
          :points_possible=>1,
          :question_type=>"multiple_answers_question",
          :correct_comments=>"",
          :migration_id=>"",
          :question_text=>"<div>go!</div>"}

  SHORT_ANSWER =
      {:answers=>[{:text=>"cat", :weight=>100}],
       :correct_comments=>"",
       :question_name=>"Short answer question",
       :incorrect_comments=>"",
       :migration_id=>"",
       :points_possible=>1,
       :question_type=>"short_answer_question",
       :question_text=>"<div>What is your answer</div>"}
  
  SHORT_ANSWER_AS_ESSAY =
      {
          :incorrect_comments=>"",
          :question_type=>"essay_question",
          :migration_id=>"",
          :question_text=>"<div>State one advantage Pandas have over Darwin.</div>",
          :answers=>[],
          :question_name=>"",
          :points_possible=>1,
          :correct_comments=>""}

  MATCHING =
      {
          :answers=>[{:right=>"1", :text=>"a", :left=>"a"}, {:right=>"2", :text=>"b", :left=>"b"}, {:right=>"3", :text=>"c", :left=>"c"}],
          :correct_comments=>"",
          :question_name=>"Matching question",
          :incorrect_comments=>"",
          :migration_id=>"",
          :points_possible=>1,
          :question_type=>"matching_question",
          :question_text=>"<div>matching question</div>",
          :matches=>[{:text=>"1"}, {:text=>"2"}, {:text=>"3"}]}

  ORDER =
      {:answers=>
           [{:text=>"1", :comments=>""},
            {:text=>"2", :comments=>""},
            {:text=>"3", :comments=>""}],
       :correct_comments=>"",
       :question_name=>"Ordering question",
       :incorrect_comments=>"",
       :migration_id=>"",
       :points_possible=>1,
       :question_type=>"matching_question",
       :question_text=>"<div>Order these</div>",
       :matches=>[{:text=>"1"}, {:text=>"2"}, {:text=>"3"}]}

  FILE_RESPONSE =
      {
          :answers=>[],
          :correct_comments=>"",
          :question_name=>"offline item?",
          :incorrect_comments=>"",
          :migration_id=>"",
          :points_possible=>1,
          :question_type=>"file_upload_question",
          :question_text=>"<div>This is an offline item. I don't know what to do.</div>",
      }

  FIB =
      {
          :answers=>
              [{:text=>"quick", :weight=>100, :comments=>"", :blank_id=>"l1"},
               {:text=>"fox", :weight=>100, :comments=>"", :blank_id=>"l2"},
               {:text=>"dog", :weight=>100, :comments=>"", :blank_id=>"l3"},
               {:text=>"0.02", :weight=>100, :comments=>"", :blank_id=>"l4"},
               {:text=>"5", :weight=>100, :comments=>"", :blank_id=>"l5"}],
          :correct_comments=>"",
          :incorrect_comments=>"",
          :question_name=>"Fill in the blank(s)",
          :migration_id=>"",
          :points_possible=>1,
          :question_text=>"<div>The [l1] brown [l2] jumped over the lazy [l3] .</div> [l4]  [l5] ",
          :question_type=>"fill_in_multiple_blanks_question"}

end
end
