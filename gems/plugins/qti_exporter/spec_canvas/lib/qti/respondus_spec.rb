require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting respondus QTI" do
  it "should convert multiple choice" do
    manifest_node=get_manifest_node('multiple_choice')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq RespondusExpected::MULTIPLE_CHOICE
  end

  it "should find correct answer for multiple choice with zero point weights" do
    hash = get_question_hash(RESPONDUS_FIXTURE_DIR, 'zero_point_mc', false, :flavor => Qti::Flavors::RESPONDUS)
    expect(hash[:import_error]).to eq nil
    expect(hash[:answers].first[:weight]).to eq 100
  end

  it "should convert algorithm question as multiple choice question" do
    manifest_node=get_manifest_node('algorithm_question')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    hash.delete :question_text #Because it's ugly html that we don't really care about.
    expect(hash).to eq RespondusExpected::ALGORITHM_QUESTION
  end

  it "should convert true false" do
    manifest_node=get_manifest_node('true_false')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq RespondusExpected::TRUE_FALSE
  end

  it "should convert multiple response" do
    manifest_node=get_manifest_node('multiple_response')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq RespondusExpected::MULTIPLE_ANSWER
  end

  it "should convert multiple response with partial credit" do
    manifest_node=get_manifest_node('multiple_response_partial')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq RespondusExpected::MULTIPLE_ANSWER2
  end

  it "should convert matching" do
    manifest_node=get_manifest_node('matching')
    hash = Qti::AssessmentItemConverter.create_instructure_question({:manifest_node=>manifest_node, :base_dir=>respondus_question_dir})
    # make sure the ids are correctly referencing each other
    matches = {}
    hash[:matches].each { |m| matches[m[:match_id]] = m[:text] }
    hash[:answers].each do |a|
      expect(matches[a[:match_id]]).to eq a[:text].upcase
    end
    # compare everything else without the ids
    hash[:answers].each { |a| a.delete(:id); a.delete(:match_id) }
    hash[:matches].each { |m| m.delete(:match_id) }
    expect(hash).to eq RespondusExpected::MATCHING
  end

  it "should convert matching with choiceInteraction interaction type" do
    manifest_node=get_manifest_node('matching', :interaction_type => 'choiceInteraction', :question_type => 'Matching')
    hash = Qti::AssessmentItemConverter.create_instructure_question({:manifest_node=>manifest_node, :base_dir=>respondus_question_dir})
    # make sure the ids are correctly referencing each other
    matches = {}
    hash[:matches].each { |m| matches[m[:match_id]] = m[:text] }
    hash[:answers].each do |a|
      expect(matches[a[:match_id]]).to eq a[:text].upcase
    end
    # compare everything else without the ids
    hash[:answers].each { |a| a.delete(:id); a.delete(:match_id) }
    hash[:matches].each { |m| m.delete(:match_id) }
    expect(hash).to eq RespondusExpected::MATCHING
  end

  it "should convert essay" do
    manifest_node=get_manifest_node('essay')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    expect(hash).to eq RespondusExpected::ESSAY
  end

  it "should convert fill in the blank (short answer)" do
    manifest_node=get_manifest_node('fill_in_the_blank')
    hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>respondus_question_dir)
    hash[:answers].each { |a| a.delete(:id) }
    expect(hash).to eq RespondusExpected::FILL_IN_THE_BLANK
  end

  it "should convert the assessment into a quiz" do
    manifest_node=get_manifest_node('assessment', :quiz_type => 'Test')
    a = Qti::AssessmentTestConverter.new(manifest_node, respondus_question_dir)
    a.create_instructure_quiz
    expect(a.quiz).to eq RespondusExpected::ASSESSMENT
  end


end

module RespondusExpected
  FILL_IN_THE_BLANK=
          {
                  :correct_comments=>"",
                  :question_name=>"Fill in the Blank Question",
                  :migration_id=>"QUE_1036",
                  :answers=>
                          [{:comments=>"", :text=>"2", :weight=>100},
                           {:comments=>"", :text=>"two", :weight=>100},
                           {:comments=>"", :text=>"abs(2)", :weight=>100}],
                  :incorrect_comments=>"",
                  :points_possible=>1,
                  :neutral_comments=>"The answer was \"2\". Or \"two\". Or I would even take \"abs(2)\"",
                  :question_type=>"short_answer_question",
                  :question_text=>"The absolute value of (-2) is __________"
          }

  ESSAY=
          {
                  :correct_comments=>"",
                  :question_name=>"Essay Question",
                  :migration_id=>"QUE_1021",
                  :answers=>[],
                  :incorrect_comments=>"",
                  :points_possible=>1,
                  :neutral_comments=>"You should have typed something coherent and meaningful into the essay box.",
                  :question_type=>"essay_question",
                  :question_text=>"Please type your essay question answer in the box below."
          }

  MATCHING =
          {
                  :correct_comments=>"",
                  :question_name=>"Matching Question",
                  :migration_id=>"QUE_1026",
                  :matches=>
                          [{:text=>"A"},
                           {:text=>"B"},
                           {:text=>"C"},
                           {:text=>"D"}],
                  :answers=>
                          [{:right=>"A", :comments=>"", :text=>"a", :left=>"a"},
                           {:right=>"B", :comments=>"", :text=>"b", :left=>"b"},
                           {:right=>"C", :comments=>"", :text=>"c", :left=>"c"},
                           {:right=>"D", :comments=>"", :text=>"d", :left=>"d"}],
                  :incorrect_comments=>"",
                  :points_possible=>1,
                  :neutral_comments=> "This should have been fairly straightforward, if you know the alphabet at all.",
                  :question_type=>"matching_question",
                  :question_text=>"Match each lowercase letter with its capitalized letter"
          }
  MULTIPLE_ANSWER2 =
          {:correct_comments=>"",
                  :question_name=>"Multiple Response -- Right less Wrong",
                  :migration_id=>"QUE_1051",
                  :answers=>
                          [{:comments=>"\"Alabaster\" starts with an \"a\", yes.",
                                   :migration_id=>"QUE_1053_A1",
                                   :text=>"Alabaster",
                                   :weight=>100},
                           {:comments=>"\"Brandish\" starts with a \"b\", so no",
                                   :migration_id=>"QUE_1054_A2",
                                   :text=>"Brandish",
                                   :weight=>0},
                           {:comments=>"\"Architecture\" starts with an \"a\", yes",
                                   :migration_id=>"QUE_1055_A3",
                                   :text=>"Architecture",
                                   :weight=>100},
                           {:comments=>"\"Streamline\" starts with an \"s\", so no",
                                   :migration_id=>"QUE_1056_A4",
                                   :text=>"Streamline",
                                   :weight=>0}],
                  :incorrect_comments=>"",
                  :points_possible=>100,
                  :neutral_comments=>
                          "\"Alabaster\" and \"architecture\" both start with an \"A\".",
                  :question_type=>"multiple_answers_question",
                  :question_text=>"Select all the words that start with an \"A\"."}
  MULTIPLE_ANSWER =
          {:correct_comments=>"",
                  :question_name=>"Multiple Response Question - All or Nothing",
                  :migration_id=>"QUE_1040",
                  :answers=>
                          [{:comments=>"\"fox\" does rhyme with \"box\", yes",
                                   :migration_id=>"QUE_1042_A1",
                                   :text=>"fox hint ... this is one of them",
                                   :html=>"fox <sup>hint ... this is one of them</sup>",
                                   :weight=>100},
                           {:comments=>"\"bacon\" does not rhyme with \"box\", no",
                                   :migration_id=>"QUE_1043_A2",
                                   :text=>"bacon",
                                   :weight=>0},
                           {:comments=>"\"clocks\" does rhyme with \"box\", yes",
                                   :migration_id=>"QUE_1044_A3",
                                   :text=>"clocks",
                                   :weight=>100},
                           {:comments=>"\"sugar\" does not rhyme with \"box\", no",
                                   :migration_id=>"QUE_1045_A4",
                                   :text=>"sugar",
                                   :weight=>0}],
                  :incorrect_comments=>"",
                  :points_possible=>100,
                  :neutral_comments=>
                          "the words \"fox\" and \"clocks\" rhyme with \"box\". I know, that was a tricky one because \"clocks\" doesn't end in \"ox\" like \"box\" and \"fox\" do.",
                  :question_type=>"multiple_answers_question",
                  :question_text=>"Select all answers that rhyme with \"box\"."}
  MULTIPLE_CHOICE =
          {       :correct_comments => '',
                  :incorrect_comments => '',
                  :question_name=>"Multiple Choice",
                  :migration_id=>"QUE_1004",
                  :answers=>
                          [{:comments=>"No, that's not \"C\", that's \"A\"",
                                   :migration_id=>"QUE_1006_A1",
                                   :text=>"A",
                                   :weight=>0},
                           {:comments=>"No, that's not \"C\", that's \"B\"",
                                   :migration_id=>"QUE_1007_A2",
                                   :text=>"B",
                                   :weight=>0},
                           {:comments=>"That's right!",
                                   :migration_id=>"QUE_1008_A3",
                                   :text=>"C ... or is it?",
                                   :html=>"C ... or <i>is</i> it?",
                                   :weight=>100},
                           {:comments=>"No, that's not \"C\", that's \"D\"",
                                   :migration_id=>"QUE_1009_A4",
                                   :text=>"E",
                                   :weight=>0}],
                  :points_possible=>1,
                  :neutral_comments=>
                          "Well, the correct answer should have been \"C\". If you didn't put that, you're wrong.",
                  :neutral_comments_html =>
                          "Well, the correct answer should have been \"C\".  If you didn't put that, you're <b>wrong</b>.",
                  :question_type=>"multiple_choice_question",
                  :question_text=>"Please select the answer \"C\""}

  TRUE_FALSE =
          {
                  :neutral_comments=> "Like I said, the correct answer should have been \"false\". If you didn't select \"false\" you deserve to be called an idiot.",
                  :answers=>
                          [{
                                   :text=>"True",
                                   :weight=>0,
                                   :migration_id=>"QUE_1017_A1"},
                           {
                                   :text=>"False",
                                   :weight=>100,
                                   :migration_id=>"QUE_1018_A2"}],
                  :question_type=>"multiple_choice_question",
                  :question_text=>"The correct answer is \"false\"",
                  :correct_comments=>"Yes, that is the correct answer!",
                  :incorrect_comments=>"No, the correct answer is \"false\"",
                  :question_name=>"True False Question",
                  :points_possible=>1,
                  :migration_id=>"QUE_1015"}
  ALGORITHM_QUESTION =
          {:correct_comments=>"",
                  :points_possible=>1,
                  :question_name=>"Algorithm Question",
                  :answers=>
                          [{:migration_id=>"QUE_1063_A1", :text=>"Answer A", :weight=>0},
                           {:migration_id=>"QUE_1064_A2", :text=>"Answer B", :weight=>0},
                           {:migration_id=>"QUE_1065_A3", :text=>"Answer C", :weight=>0},
                           {:migration_id=>"QUE_1066_A4", :text=>"Answer D", :weight=>100},
                           {:migration_id=>"QUE_1067_A5", :text=>"Answer E", :weight=>0}],
                  :migration_id=>"QUE_1061",
                  :question_type=>"multiple_choice_question",
                  :incorrect_comments=>""}
  ASSESSMENT =
          {:points_possible=>"237.0",
                  :migration_id=>"neutral",
                  :grading=>
                          {:points_possible=>"237.0",
                                  :due_date=>nil,
                                  :migration_id=>"neutral",
                                  :grade_type=>"numeric",
                                  :title=>"neutral",
                                  :weight=>nil},
                  :question_count=>8,
                  :quiz_type=>"assignment",
                  :questions=>
                          [{:migration_id=>"QUE_1004", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1015", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1021", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1026", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1036", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1040", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1051", :question_type=>"question_reference"},
                           {:migration_id=>"QUE_1061", :question_type=>"question_reference"}],
                  :title=>"neutral",
                  :quiz_name=>"neutral"}
end
end
