require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting D2L QTI" do
  before do
    @opts = { :flavor => Qti::Flavors::D2L }
  end

  it "should convert multiple choice" do
    get_question_hash(d2l_question_dir, 'multiple_choice', true, @opts).should == D2LExpected::MULTIPLE_CHOICE
  end

  it "should convert true false" do
    get_question_hash(d2l_question_dir, 'true_false', true, @opts).should == D2LExpected::TRUE_FALSE
  end

  it "should convert short answer" do
    get_question_hash(d2l_question_dir, 'short_answer', true, @opts).should == D2LExpected::SHORT_ANSWER
  end

  it "should convert multi select" do
    get_question_hash(d2l_question_dir, 'multi_select', true, @opts).should == D2LExpected::MULTI_SELECT
  end
  
  it "should convert multiple short" do
    get_question_hash(d2l_question_dir, 'multiple_short', true, @opts).should == D2LExpected::MULTIPLE_SHORT
  end
  
  it "should convert fill in the blank with multiple blanks" do
    get_question_hash(d2l_question_dir, 'fib', true, @opts).should == D2LExpected::FIB
  end
  
  it "should convert matching" do
    #pp get_question_hash(d2l_question_dir, 'matching', false)
    hash = get_question_hash(d2l_question_dir, 'matching', false, @opts)
    matches = {}
    hash[:matches].each {|m| matches[m[:match_id]] = m[:text]}
    hash[:answers].each do |a|
      matches[a[:match_id]].should == a[:right]
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    hash.should == D2LExpected::MATCHING
  end
  
  it "should flag ordering question as an error" do
    get_question_hash(d2l_question_dir, 'ordering', true, @opts).should == D2LExpected::ORDERING
  end
  
  it "should convert math question" do
    get_question_hash(d2l_question_dir, 'math', true, @opts).should == D2LExpected::MATH
  end

  it "should convert long answer" do
    get_question_hash(d2l_question_dir, 'long_answer', true, @opts).should == D2LExpected::LONG_ANSWER
  end

  it "should convert an item with a response condition with no condition" do
    get_question_hash(d2l_question_dir, 'no_condition', true, @opts).should == D2LExpected::NO_CONDITION
  end

  it "should convert the assessment into a quiz" do
    get_quiz_data(d2l_question_dir, 'assessment', @opts).last.first.should == D2LExpected::ASSESSMENT
  end

  it "should convert the assessment into a quiz" do
    get_quiz_data(d2l_question_dir, 'assessment_references', @opts).last.first.should == D2LExpected::ASSESSMENT_REFS
  end

end

module D2LExpected

  MULTIPLE_CHOICE =
          {
                  :incorrect_comments=>"",
                  :question_bank_name=>"02gilback",
                  :answers=>
                          [
                                  {:weight=>100,
                                   :text=>"alpha",
                                   :migration_id=>"QUES_516156_630296_A2899442",
                                   :comments=>""},
                                  {:weight=>0,
                                   :text=>"beta",
                                   :migration_id=>"QUES_516156_630296_A2899443",
                                   :comments=>""},
                                  {:weight=>0,
                                   :text=>"gamma",
                                   :migration_id=>"QUES_516156_630296_A2899444"},
                                  {:weight=>0,
                                   :text=>"omega",
                                   :migration_id=>"QUES_516156_630296_A2899445"}
                          ],
                  :question_bank_id=>"SECT_3981973",
                  :points_possible=>1,
                  :migration_id=>"QUES_516156_630296",
                  :question_text=>"The first letter of the Greek alphabet is?",
                  :question_name=>"",
                  :correct_comments=>"",
                  :question_type=>"multiple_choice_question"
          }
  
  TRUE_FALSE =
          {:question_type=>"multiple_choice_question",
           :incorrect_comments=>"",
           :points_possible=>1,
           :answers=>
                   [{:text=>"True",
                     :weight=>100,
                     :migration_id=>"QUES_968903_1181388_A4710345",
                     :comments=>"True is correct"},
                    {:text=>"False",
                     :weight=>0,
                     :migration_id=>"QUES_968903_1181388_A4710346",
                     :comments=>"False is not correct",
                     :comments_html=>"False is <strong>not</strong> correct"}],
           :question_text=>
                   "<p>Is this <strong>true</strong> or false?</p><img src=\"quizzing/bunny_consumer.png\" alt=\"\">",
           :question_name=>"true false questions",
           :migration_id=>"QUES_968903_1181388",
           :correct_comments=>""}

  ASSESSMENT = {:migration_id=>"res_quiz_90521",
                :question_count=>2,
                :title=>"01 Early Bird Storybook Week 2",
                :quiz_name=>"01 Early Bird Storybook Week 2",
                :quiz_type=>nil,
                :questions=>[{:migration_id=>"QUES_443669_562987", :question_type=>"question_reference"},
                             {:migration_id=>"QUES_443669_123456", :question_type=>"question_reference"}],
                :time_limit => 15,
                :allowed_attempts=>-1,
                :assignment_migration_id=>'435646'
  }

  ASSESSMENT_REFS = {:title=>"Quiz 2",
                     :allowed_attempts=>3,
                     :quiz_name=>"Quiz 2",
                     :migration_id=>"res_quiz_39018",
                     :quiz_type=>nil,
                     :questions=>
                             [{:points_possible=>1,
                               :migration_id=>"QUES_516156_630296",
                               :question_type=>"question_reference"},
                              {:points_possible=>1,
                               :migration_id=>"QUES_516157_630297",
                               :question_type=>"question_reference"},
                              {:points_possible=>1,
                               :migration_id=>"QUES_516158_630298",
                               :question_type=>"question_reference"}],
                     :question_count=>3,
                     :time_limit=>15,
                     :access_code=>"insecure",
                     :assignment_migration_id=>'164842'}
  
  LONG_ANSWER = {:question_bank_name=>"02gilback",
                 :points_possible=>1,
                 :answers=>[],
                 :question_text=>"Write an essay on writing essays",
                 :question_name=>"",
                 :migration_id=>"QUES_516158_630298",
                 :correct_comments=>"",
                 :question_type=>"essay_question",
                 :incorrect_comments=>"",
                 :question_bank_id=>"SECT_3981973"}

  SHORT_ANSWER = {:question_type=>"short_answer_question",
                  :incorrect_comments=>"",
                  :question_bank_id=>"SECT_3981973",
                  :question_bank_name=>"02gilback",
                  :points_possible=>1,
                  :answers=>[{:weight=>100, :text=>"Nydam", :comments=>""}],
                  :question_text=>"Who is winning the Tour of California today?",
                  :question_name=>"",
                  :migration_id=>"QUES_522317_638596",
                  :correct_comments=>""}
  
  MULTI_SELECT = {:correct_comments=>"",
                  :question_type=>"multiple_answers_question",
                  :incorrect_comments=>"",
                  :question_bank_id=>"SECT_3981973",
                  :question_bank_name=>"02gilback",
                  :points_possible=>1,
                  :answers=>
                          [{:text=>"1", :weight=>0, :migration_id=>"QUES_968905_1181391_A4710353"},
                           {:text=>"2", :weight=>100, :migration_id=>"QUES_968905_1181391_A4710354"},
                           {:text=>"3", :weight=>0, :migration_id=>"QUES_968905_1181391_A4710355"},
                           {:text=>"4", :weight=>100, :migration_id=>"QUES_968905_1181391_A4710356"}],
                  :question_text=>"<p>how about the even numbers?</p>",
                  :question_name=>"multi select",
                  :migration_id=>"QUES_968905_1181391"}

  MULTIPLE_SHORT = {:question_name=>"multiple short answer",
                    :migration_id=>"QUES_968910_1181396",
                    :correct_comments=>"",
                    :question_type=>"short_answer_question",
                    :incorrect_comments=>"",
                    :question_bank_id=>"SECT_3981973",
                    :question_bank_name=>"02gilback",
                    :points_possible=>1,
                    :answers=>
                            [{:comments=>"", :text=>"answer 1", :weight=>100},
                             {:comments=>"", :text=>"answer 2", :weight=>100},
                             {:comments=>"", :text=>"answer 3", :weight=>100}],
                    :question_text=>"<p>What is a multiple short answer?</p>"}

  MATCHING = {:question_text=>"<p>letter to number</p>",
              :question_name=>"matching",
              :migration_id=>"QUES_968912_1181398",
              :matches=>
                      [{:html=>"<strong>1</strong>", :text=>'1'},
                       {:html=>"<span style=\"text-decoration: underline;\">2</span>", :text=>'2'}],
              :correct_comments=>"",
              :question_type=>"matching_question",
              :incorrect_comments=>"",
              :question_bank_id=>"SECT_3981973",
              :question_bank_name=>"02gilback",
              :points_possible=>1,
              :answers=>
                      [{:right=>"1",
                        :html=>"<em><strong>A</strong></em>",
                        :left_html=>"<em><strong>A</strong></em>",
                        :comments=>"",
                        :text=>"A",
                        :left=>"A"},
                       {:right=>"2", 
                        :comments=>"", 
                        :text=>"b", 
                        :left=>"b"}]}

  ORDERING = {:question_bank_id=>"SECT_3981973",
              :answers=>[],
              :incorrect_comments=>"",
              :qti_error=>"There was an error exporting an assessment question - No question type used when trying to parse a qti question",
              :points_possible=>1,
              :question_bank_name=>"02gilback",
              :question_text=>"<p>the alphabet, heard of it?</p>",
              :question_name=>"ordering question",
              :migration_id=>"QUES_968913_1181399",
              :correct_comments=>"",
              :question_type=>"Error"}

  MATH = {:answers=>[],
          :question_type=>"calculated_question",
          :formulas=>[],
          :question_bank_id=>"SECT_3981973",
          :incorrect_comments=>"",
          :imported_formula=>"2 * {x}   {y} - {z}",
          :points_possible=>1,
          :question_bank_name=>"02gilback",
          :question_text=>"<p>Solve the formula:</p>",
          :question_name=>"multi variable math",
          :migration_id=>"QUES_979792_1194510",
          :variables=>
                  [{:scale=>3, :min=>10, :max=>15, :name=>"x"},
                   {:scale=>1, :min=>0.1, :max=>0.9, :name=>"y"},
                   {:scale=>0, :min=>100, :max=>150, :name=>"z"}],
          :correct_comments=>""}

  FIB = {:migration_id=>"QUES_979782_1194494",
         :answers=>
                 [{:blank_id=>"QUES_979782_1194494_A4749142", :text=>"fill", :weight=>100},
                  {:blank_id=>"QUES_979782_1194494_A4749142", :text=>"guess", :weight=>100},
                  {:blank_id=>"QUES_979782_1194494_A4749144", :text=>"questions", :weight=>100}],
         :correct_comments=>"",
         :question_type=>"fill_in_multiple_blanks_question",
         :question_bank_id=>"SECT_3981973",
         :incorrect_comments=>"",
         :points_possible=>1,
         :question_bank_name=>"02gilback",
         :question_text=> "This a weird way to do [QUES_979782_1194494_A4749142] in the blank [QUES_979782_1194494_A4749144] ",
         :question_name=>""}

  NO_CONDITION = {:question_name => "",
                  :migration_id => "QUES_969100_1181698",
                  :answers =>
                          [{:text => "Avoid pseudo-forgetting",
                            :migration_id => "QUES_969100_1181698_A4711381",
                            :weight => 100},
                           {:text => "Limit what you learn",
                            :migration_id => "QUES_969100_1181698_A4711382",
                            :weight => 100},
                           {:text => "Arrive at meaningful patterns",
                            :migration_id => "QUES_969100_1181698_A4711383",
                            :weight => 100},
                           {:text => "Study in long periods",
                            :migration_id => "QUES_969100_1181698_A4711384",
                            :weight => 0},
                           {:text => "Use positive self-talk",
                            :migration_id => "QUES_969100_1181698_A4711385",
                            :weight => 100}],
                  :correct_comments => "",
                  :question_type => "multiple_answers_question",
                  :question_bank_id => "SECT_3981973",
                  :incorrect_comments => "",
                  :points_possible => 1,
                  :question_bank_name => "02gilback",
                  :question_text => "<p>According to the class handout Basic Principles to Enhance Memory which of the following are effective ways to remember?</p>"}
end
end
