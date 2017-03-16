require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "Converting Blackboard 8 qti" do

  it "should convert multiple choice" do
    expect(get_question_hash(bb8_question_dir, 'multiple_choice')).to eq BB8Expected::MULTIPLE_CHOICE
  end

  it "should convert multiple choice with blanke answers" do
    expect(get_question_hash(bb8_question_dir, 'multiple_choice_blank_answers')).to eq BB8Expected::MULTIPLE_CHOICE_BLANK_ANSWERS
  end

  it "should convert either/or (yes/no) into multiple choice" do
    expect(get_question_hash(bb8_question_dir, 'either_or_yes_no')).to eq BB8Expected::EITHER_OR_YES_NO
  end

  it "should convert either/or (agree/disagree) into multiple choice" do
    expect(get_question_hash(bb8_question_dir, 'either_or_agree_disagree')).to eq BB8Expected::EITHER_OR_AGREE_DISAGREE
  end

  it "should convert either/or (true/false) into multiple choice" do
    expect(get_question_hash(bb8_question_dir, 'either_or_true_false')).to eq BB8Expected::EITHER_OR_TRUE_FALSE
  end

  it "should convert either/or (right/wrong) into multiple choice" do
    expect(get_question_hash(bb8_question_dir, 'either_or_right_wrong')).to eq BB8Expected::EITHER_OR_RIGHT_WRONG
  end

  it "should convert multiple answer questions" do
    expect(get_question_hash(bb8_question_dir, 'multiple_answer')).to eq BB8Expected::MULTIPLE_ANSWER
  end

  it "should convert true/false questions" do
    expect(get_question_hash(bb8_question_dir, 'true_false')).to eq BB8Expected::TRUE_FALSE
  end

  it "should convert essay questions" do
    expect(get_question_hash(bb8_question_dir, 'essay')).to eq BB8Expected::ESSAY
  end

  it "should convert short answer questions" do
    expect(get_question_hash(bb8_question_dir, 'short_response')).to eq BB8Expected::SHORT_RESPONSE
  end

  it "should convert matching questions" do
    hash = get_question_hash(bb8_question_dir, 'matching', false)
    matches = {}
    hash[:matches].each {|m| matches[m[:match_id]] = m[:text]}
    hash[:answers].each do |a|
      expect(matches[a[:match_id]]).to eq a[:text].sub('left', 'right')
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq BB8Expected::MATCHING
  end

  it "should convert opinion scale/likert questions into multiple choice questions" do
    expect(get_question_hash(bb8_question_dir, 'likert')).to eq BB8Expected::LIKERT
  end

  it "should convert fill in the blank questions into short answer question"do
    expect(get_question_hash(bb8_question_dir, 'fill_in_the_blank')).to eq BB8Expected::FILL_IN_THE_BLANK
  end

  it "should flag file response questions as not supported" do
    expect(get_question_hash(bb8_question_dir, 'file_upload')).to eq BB8Expected::FILE_RESPONSE
  end

  it "should flag hotspot questions as not supported" do
    expect(get_question_hash(bb8_question_dir, 'hot_spot')).to eq BB8Expected::HOT_SPOT
  end

  it "should flag quiz bowl questions as not supported" do
    expect(get_question_hash(bb8_question_dir, 'quiz_bowl')).to eq BB8Expected::QUIZ_BOWL
  end

  it "should convert fill in multiple blanks questions" do
    expect(get_question_hash(bb8_question_dir, 'fill_in_the_blank_plus')).to eq BB8Expected::FILL_IN_MULTIPLE_BLANKS
  end

  it "should convert jumbled sentence questions" do
    expect(get_question_hash(bb8_question_dir, 'jumbled_sentence')).to eq BB8Expected::JUMBLED_SENTENCE
  end

  it "should convert ordering questions into matching questions" do
    hash = get_question_hash(bb8_question_dir, 'ordering')
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq BB8Expected::ORDER
  end

  it "should convert simple calculated questions" do
    expect(get_question_hash(bb8_question_dir, 'calculated_simple')).to eq BB8Expected::CALCULATED_SIMPLE
  end

  it "should convert complex calculated questions" do
    expect(get_question_hash(bb8_question_dir, 'calculated_complex')).to eq BB8Expected::CALCULATED_COMPLEX
  end

  it "should convert calculated numeric questions" do
    expect(get_question_hash(bb8_question_dir, 'calculated_numeric')).to eq BB8Expected::CALCULATED_NUMERIC
  end

  it "should convert the assessments into quizzes" do
    manifest_node=get_manifest_node('assessment', :quiz_type => 'Test')
    a = Qti::AssessmentTestConverter.new(manifest_node, bb8_question_dir)
    a.create_instructure_quiz
    expect(a.quiz).to eq BB8Expected::ASSESSMENT
  end

  it "should grab multiple html divs" do
    hash = get_question_hash(bb8_question_dir, 'with_image')
    expect(hash[:question_text]).to eq "San Jose, purple on this map, is an example of a ___________ culture region.\n<br/>\n<img src=\"5e19c40a33964748a1ec13af98715c7f/Picture3.jpg\" alt=\"Picture3.jpg\">"
  end

end

module BB8Expected
  # the multiple choice example minus the ids for the answers because those are random.
  MULTIPLE_CHOICE = {:answers=>
          [{:text=>"nose",
            :weight=>100,
            :migration_id=>"RESPONSE_595202876ccd425a9b4fe9e8e257292d"},
           {:text=>"ear",
            :weight=>0,
            :migration_id=>"RESPONSE_29b3b04b609c4a7abbf882e9b89b26ea"},
           {:text=>"eye",
            :weight=>0,
            :migration_id=>"aa35aa6b600844e1b42fd493cb0f0da7"},
           {:text=>"mouth",
            :weight=>0,
            :migration_id=>"b83b61f6356a410892de7f9c4a99b669"}],
                     :correct_comments=>"right",
                     :incorrect_comments=>"wrong",
                     :points_possible=>10.0,
                     :question_type=>"multiple_choice_question",
                     :question_name=>"",
                     :question_text=>"The answer is nose.<br>",
                     :migration_id=>"_154767_1"}

  MULTIPLE_CHOICE_BLANK_ANSWERS = {:question_name=>"",
                                   :question_text=>"This is a great question.<br>",
                                   :incorrect_comments=>"",
                                   :question_type=>"multiple_choice_question",
                                   :answers=>
                                           [{:text=>"True",
                                             :weight=>0,
                                             :migration_id=>"RESPONSE_44dc8fdb5e0a4c0c99de864f8a4ca983"},
                                            {:text=>"False",
                                             :weight=>100,
                                             :migration_id=>"RESPONSE_73478560c56547f08cdc3eec5e363775"},
                                            {:text=>"No answer text provided.",
                                             :weight=>0,
                                             :migration_id=>"RESPONSE_78e36a7831e84a0f94ce01a151771f94"},
                                            {:text=>"No answer text provided.",
                                             :weight=>0,
                                             :migration_id=>"RESPONSE_686165cd422f45669b6be25b4f90f5de"}],
                                   :migration_id=>"_154777_1",
                                   :correct_comments=>"",
                                   :points_possible=>17.0}


  # removed ids on the answers
  TRUE_FALSE = {:answers=>
          [{:text=>"True", :weight=>100, :migration_id=>"true"},
           {:text=>"False", :weight=>0, :migration_id=>"false"}],
                :correct_comments=>"yep",
                :incorrect_comments=>"nope",
                :points_possible=>10.0,
                :question_type=>"true_false_question",
                :question_name=>"",
                :question_text=>"I am wearing a black hat.<br>",
                :migration_id=>"_154772_1"}

  # removed ids on the answers
  MULTIPLE_ANSWER = {:answers=>
          [{:text=>"house",
            :weight=>100,
            :migration_id=>"RESPONSE_21c52601c6b545b39aab43c56749c2eb"},
           {:text=>"garage",
            :weight=>100,
            :migration_id=>"RESPONSE_2095979784cd45c9bcec8d303225ae16"},
           {:text=>"barn",
            :weight=>0,
            :migration_id=>"RESPONSE_08f1bd768b044f47881067ab7fcabac6"},
           {:text=>"pond",
            :weight=>0,
            :migration_id=>"dc9f2f878ce64fddbe762721e26fa11c"}],
                     :correct_comments=>"right",
                     :incorrect_comments=>"wrong",
                     :points_possible=>10.0,
                     :question_type=>"multiple_answers_question",
                     :question_name=>"",
                     :question_text=>"The answers are house and garage.<br>",
                     :migration_id=>"_154766_1"}

  ESSAY = {:example_solution=>"Nobody.",
           :migration_id=>"_154759_1",
           :answers=>[],
           :correct_comments=>"",
           :points_possible=>23.0,
           :question_name=>"",
           :question_text=>"Who likes to use Blackboard?<br>",
           :incorrect_comments=>"",
           :question_type=>"essay_question"}

  SHORT_RESPONSE =  {:migration_id=>"_154771_1",
                     :answers=>[],
                     :example_solution=>"A yellow submarine.",
                     :correct_comments=>"",
                     :incorrect_comments=>"",
                     :points_possible=>10.0,
                     :question_type=>"essay_question",
                     :question_name=>"",
                     :question_text=>"We all live in what?<br>"}

  # removed ids on the answers
  MATCHING = {:answers=>
          [{:right=>"right 1", :text=>"left 1", :left=>"left 1", :comments=>""},
           {:right=>"right 2", :text=>"left 2", :left=>"left 2", :comments=>""},
           {:right=>"right 3", :text=>"left 3", :left=>"left 3", :comments=>""},
           {:right=>"right 4", :text=>"left 4", :left=>"left 4", :comments=>""}],
              :correct_comments=>"right",
              :incorrect_comments=>"wrong",
              :points_possible=>10.0,
              :question_type=>"matching_question",
              :question_name=>"",
              :question_text=>"Match these.<br>",
              :migration_id=>"_154765_1",
              :matches=>
                      [{:text=>"right 1"},
                       {:text=>"right 2"},
                       {:text=>"right 4"},
                       {:text=>"right 3"}]}

  LIKERT = {:answers=>
          [{:text=>"Strongly Agree",
            :weight=>100,
            :migration_id=>"RESPONSE_92f3633c39ff48a196b6f4c8fa5aa5cd"},
           {:text=>"Agree",
            :weight=>0,
            :migration_id=>"RESPONSE_71488ef738be49f18a724416eeab4386"},
           {:text=>"Neither Agree nor Disagree",
            :weight=>0,
            :migration_id=>"RESPONSE_61de00cfc52f43b79df933f886a4ccf9"},
           {:text=>"Disagree",
            :weight=>0,
            :migration_id=>"RESPONSE_82f60ef8ea194085bcb27efc7e50d24e"},
           {:text=>"Strongly Disagree",
            :weight=>0,
            :migration_id=>"d1d1010136854e07a8d24cff094c2201"},
           {:text=>"Not Applicable",
            :weight=>0,
            :migration_id=>"RESPONSE_159976c1152c4a10ace02ae35e27840e"}],
            :incorrect_comments=>"wrong?",
            :points_possible=>10.0,
            :question_type=>"multiple_choice_question",
            :question_name=>"",
            :migration_id=>"_154768_1",
            :question_text=>"You love Blackboard<br>",
            :correct_comments=>"right?"}

  FILL_IN_THE_BLANK = {:question_text=>"The answer is 'purple'.<br>",
                       :answers=>
                               [{:text=>"purple", :comments=>"", :weight=>100},
                                {:text=>"violet", :comments=>"", :weight=>100}],
                       :correct_comments=>"right",
                       :incorrect_comments=>"wrong",
                       :points_possible=>10.0,
                       :question_type=>"short_answer_question",
                       :question_name=>"",
                       :migration_id=>"_154762_1"}

  EITHER_OR_YES_NO = {:question_name=>"",
                      :answers=>
                              [{:text=>"yes", :migration_id=>"yes_no_true", :weight=>0},
                               {:text=>"no",
                                :migration_id=>"yes_no_false",
                                :weight=>100}],
                      :migration_id=>"_154773_1",
                      :question_text=>"Either or question with yes/no",
                      :correct_comments=>"right answer",
                      :incorrect_comments=>"Wrong answer",
                      :points_possible=>10.0,
                      :question_type=>"multiple_choice_question"}

  EITHER_OR_AGREE_DISAGREE = {:question_type=>"multiple_choice_question",
                              :answers=>
                                      [{:text=>"agree", :weight=>0, :migration_id=>"agree_disagree_true"},
                                       {:text=>"disagree",
                                        :weight=>100,
                                        :migration_id=>"agree_disagree_false"}],
                              :question_name=>"",
                              :migration_id=>"_154774_1",
                              :question_text=>"Either or question with agree/disagree.",
                              :correct_comments=>"correct answer",
                              :incorrect_comments=>"wrong answer",
                              :points_possible=>10.0}

  EITHER_OR_TRUE_FALSE = {:question_type=>"multiple_choice_question",
                          :answers=>
                                  [{:text=>"true", :weight=>0, :migration_id=>"true_false_true"},
                                   {:text=>"false",
                                    :weight=>100,
                                    :migration_id=>"true_false_false"}],
                          :question_name=>"",
                          :migration_id=>"_154775_1",
                          :question_text=>"Either/or question with true/false options",
                          :correct_comments=>"r",
                          :incorrect_comments=>"w",
                          :points_possible=>10.0}

  EITHER_OR_RIGHT_WRONG = {:question_type=>"multiple_choice_question",
                           :answers=>
                                   [{:text=>"right",
                                     :weight=>100,
                                     :migration_id=>"right_wrong_true"},
                                    {:text=>"wrong", :weight=>0, :migration_id=>"right_wrong_false"}],
                           :question_name=>"",
                           :migration_id=>"_154776_1",
                           :question_text=>"A duck is either a bird or a plane.<br>",
                           :correct_comments=>"right",
                           :incorrect_comments=>"wrong",
                           :points_possible=>7.0}

  FILE_RESPONSE = {:correct_comments=>"",
                   :answers=>[],
                   :incorrect_comments=>"",
                   :points_possible=>10.0,
                   :unsupported=>true,
                   :question_type=>"File Upload",
                   :question_name=>"",
                   :migration_id=>"_154760_1",
                   :question_text=>"File response question. I don't know what this is.<br>"}

  HOT_SPOT = {:answers=>[],
              :question_name=>"",
              :migration_id=>"_154763_1",
              :question_text=>"Where are the nuts?<br>\n<br/>\n<img src=\"4caf48de86ab4a67ad0c294e3f228ae3/chipmunk.jpg\" alt=\"chipmunk.jpg\">",
              :correct_comments=>"",
              :incorrect_comments=>"",
              :unsupported=>true,
              :points_possible=>10.0,
              :question_type=>"Hot Spot"}

  QUIZ_BOWL = {:answers=>[],
               :question_type=>"Quiz Bowl",
               :question_name=>"",
               :migration_id=>"_154770_1",
               :question_text=>"Yellow",
               :correct_comments=>"",
               :incorrect_comments=>"",
               :unsupported=>true,
               :points_possible=>10.0}

  FILL_IN_MULTIPLE_BLANKS = {:answers=>
          [{:text=>"poor", :comments=>"", :blank_id=>"1", :weight=>100},
           {:text=>"sad", :comments=>"", :blank_id=>"1", :weight=>100},
           {:text=>"boy", :comments=>"", :blank_id=>"kind-of-being", :weight=>100},
           {:text=>"poor", :comments=>"", :blank_id=>"2-a", :weight=>100},
           {:text=>"destitute", :comments=>"", :blank_id=>"2-a", :weight=>100},
           {:text=>"family", :comments=>"", :blank_id=>"family", :weight=>100}],
                             :incorrect_comments=>"wrong",
                             :points_possible=>10.0,
                             :question_type=>"fill_in_multiple_blanks_question",
                             :question_name=>"",
                             :migration_id=>"_154761_1",
                             :question_text=>"I'm just a [1] [kind-of-being] from a [2-a] [family]<br>",
                             :correct_comments=>"right"}

  JUMBLED_SENTENCE = {
          :answers=>
                  [
                          {:text=>"brown", :blank_id=>"brown", :weight=>100, :migration_id=>"RESPONSE_8197c164fada4325968bb1a0a031bb01"},
                          {:text=>"jumped", :blank_id=>"brown", :weight=>0, :migration_id=>"RESPONSE_6aeed8b3413b432cb706243be1e44d99"},
                          {:text=>"fence", :blank_id=>"brown", :weight=>0, :migration_id=>"fb1be73070444e31b8c7d349bc1f0144"},
                          {:text=>"ditch", :blank_id=>"brown", :weight=>0, :migration_id=>"a7fd8ffef02647ca82c9f4097fd1b088"},
                          {:text=>"brown", :blank_id=>"jumped", :weight=>0, :migration_id=>"RESPONSE_8197c164fada4325968bb1a0a031bb01"},
                          {:text=>"jumped", :blank_id=>"jumped", :weight=>100, :migration_id=>"RESPONSE_6aeed8b3413b432cb706243be1e44d99"},
                          {:text=>"fence", :blank_id=>"jumped", :weight=>0, :migration_id=>"fb1be73070444e31b8c7d349bc1f0144"},
                          {:text=>"ditch", :blank_id=>"jumped", :weight=>0, :migration_id=>"a7fd8ffef02647ca82c9f4097fd1b088"},
                          {:text=>"brown", :blank_id=>"fence", :weight=>0, :migration_id=>"RESPONSE_8197c164fada4325968bb1a0a031bb01"},
                          {:text=>"jumped", :blank_id=>"fence", :weight=>0, :migration_id=>"RESPONSE_6aeed8b3413b432cb706243be1e44d99"},
                          {:text=>"fence", :blank_id=>"fence", :weight=>100, :migration_id=>"fb1be73070444e31b8c7d349bc1f0144"},
                          {:text=>"ditch", :blank_id=>"fence", :weight=>0, :migration_id=>"a7fd8ffef02647ca82c9f4097fd1b088"},
                  ],
          :incorrect_comments=>"wrong",
          :points_possible=>10.0,
          :question_type=>"multiple_dropdowns_question",
          :question_name=>"",
          :migration_id=>"_154764_1",
          :question_text=>"The quick [brown] fox [jumped] over the [fence].<br>" ,
          :correct_comments=>"right"
  }

  ORDER = {:answers=>
          [{:text=>"1", :comments=>""},
           {:text=>"2", :comments=>""},
           {:text=>"3", :comments=>""},
           {:text=>"4", :comments=>""}],
           :correct_comments=>"right",
           :incorrect_comments=>"wrong",
           :points_possible=>10.0,
           :question_type=>"matching_question",
           :question_name=>"",
           :question_text=>"It is in numerical order.<br>",
           :migration_id=>"_154769_1",
           :matches=>
                   [{:text=>"b"},
                    {:text=>"a"},
                    {:text=>"c"},
                    {:text=>"d"}]}

  CALCULATED_SIMPLE = {:question_type=>"calculated_question",
                       :variables=>[{:min=>-10, :max=>10, :name=>"x", :scale=>0}],
                       :answers=>
                               [{:variables=>[{:value=>1, :name=>"x"}], :weight=>100, :answer=>9},
                                {:variables=>[{:value=>2, :name=>"x"}], :weight=>100, :answer=>8},
                                {:variables=>[{:value=>-6, :name=>"x"}], :weight=>100, :answer=>16},
                                {:variables=>[{:value=>4, :name=>"x"}], :weight=>100, :answer=>6},
                                {:variables=>[{:value=>-6, :name=>"x"}], :weight=>100, :answer=>16},
                                {:variables=>[{:value=>0, :name=>"x"}], :weight=>100, :answer=>10},
                                {:variables=>[{:value=>-5, :name=>"x"}], :weight=>100, :answer=>15},
                                {:variables=>[{:value=>7, :name=>"x"}], :weight=>100, :answer=>3},
                                {:variables=>[{:value=>0, :name=>"x"}], :weight=>100, :answer=>10},
                                {:variables=>[{:value=>-8, :name=>"x"}], :weight=>100, :answer=>18}],
                       :partial_credit_points_percent=>25,
                       :unit_points_percent=>15,
                       :question_name=>"",
                       :answer_tolerance=>0,
                       :migration_id=>"_154757_1",
                       :unit_value=>"cm",
                       :question_text=>"What is 10 - [x]?<br>",
                       :imported_formula=>"<math><apply><minus/><cn>10</cn><ci>x</ci></apply></math>",
                       :correct_comments=>"You got it right!",
                       :unit_required=>true,
                       :partial_credit_tolerance=>0.1,
                       :incorrect_comments=>"You got it wrong...",
                       :formulas=>[{:formula => "<math><apply><minus/><cn>10</cn><ci>x</ci></apply></math>"}],
                       :unit_case_sensitive=>false,
                       :points_possible=>10}

  CALCULATED_COMPLEX = {:question_type=>"calculated_question",
                        :variables=>
                                [{:min=>20, :max=>50, :name=>"F", :scale=>0},
                                 {:min=>20, :max=>40, :name=>"Y", :scale=>0},
                                 {:min=>4, :max=>6, :name=>"i", :scale=>2},
                                 {:min=>20, :max=>120, :name=>"n", :scale=>0},
                                 {:min=>5, :max=>7, :name=>"r", :scale=>0}],
                        :answers=>
                                [{:weight=>100, :variables=>[{:value=>20, :name=>"F"}, {:value=>37, :name=>"Y"}, {:value=>5.73, :name=>"i"}, {:value=>115, :name=>"n"}, {:value=>6.54, :name=>"r"}], :answer=>113.094}, {:weight=>100, :variables=>[{:value=>49, :name=>"F"}, {:value=>22, :name=>"Y"}, {:value=>4.31, :name=>"i"}, {:value=>48, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>107.024}, {:weight=>100, :variables=>[{:value=>48, :name=>"F"}, {:value=>37, :name=>"Y"}, {:value=>5.53, :name=>"i"}, {:value=>26, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>92.983}, {:weight=>100, :variables=>[{:value=>22, :name=>"F"}, {:value=>21, :name=>"Y"}, {:value=>4.49, :name=>"i"}, {:value=>35, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>104.845}, {:weight=>100, :variables=>[{:value=>21, :name=>"F"}, {:value=>34, :name=>"Y"}, {:value=>5.97, :name=>"i"}, {:value=>111, :name=>"n"}, {:value=>6, :name=>"r"}], :answer=>102.228}, {:weight=>100, :variables=>[{:value=>28, :name=>"F"}, {:value=>37, :name=>"Y"}, {:value=>4.12, :name=>"i"}, {:value=>81, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>115.316}, {:weight=>100, :variables=>[{:value=>29, :name=>"F"}, {:value=>39, :name=>"Y"}, {:value=>5.48, :name=>"i"}, {:value=>39, :name=>"n"}, {:value=>6, :name=>"r"}], :answer=>108.149}, {:weight=>100, :variables=>[{:value=>46, :name=>"F"}, {:value=>32, :name=>"Y"}, {:value=>4.42, :name=>"i"}, {:value=>58, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>108.877}, {:weight=>100, :variables=>[{:value=>22, :name=>"F"}, {:value=>36, :name=>"Y"}, {:value=>4.6, :name=>"i"}, {:value=>95, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>107.317}, {:weight=>100, :variables=>[{:value=>48, :name=>"F"}, {:value=>39, :name=>"Y"}, {:value=>4.59, :name=>"i"}, {:value=>119, :name=>"n"}, {:value=>5, :name=>"r"}], :answer=>108.153}],
                        :partial_credit_points_percent=>0,
                        :unit_points_percent=>0.0,
                        :question_name=>"",
                        :answer_tolerance=>0.1,
                        :migration_id=>"_153086_1",
                        :question_text=>
                                "Based on her excellent performance as a district sales manager, Maria receives a sizable bonus at work. Since her generous salary is more than enough to provide for the needs of her family, she decides to use the bonus to buy a bond as an investment. The par value of the bond that Maria would like to purchase is $[F] thousand. The bond pays [r]% interest, compounded semiannually (with payment on January 1 and July 1) and matures on July 1, 20[Y]. Maria wants a return of [i]%, compounded semiannually. How much would she be willing to pay for the bond if she buys it [n] days after the July 2010 interest anniversary? Give your answer in the format of a quoted bond price, as a percentage of par to three decimal places -- like you would see in the Wall Street Journal. Use the formula discussed in class -- and from the book, NOT the HP 12c bond feature. (Write only the digits, to three decimal palces, e.g. 114.451 and no $, commas, formulas, etc.)",
                        :imported_formula=>
                                "<math><apply><times/><apply><power/><apply><times/><cn>10</cn><ci>F</ci></apply><apply><minus/><cn>1</cn></apply></apply><apply><plus/><apply><times/><cn>1000</cn><ci>F</ci><ci>r</ci><apply><power/><ci>i</ci><apply><minus/><cn>1</cn></apply></apply><apply><minus/><cn>1</cn><apply><power/><apply><plus/><cn>1</cn><apply><divide/><ci>i</ci><cn>200</cn></apply></apply><apply><minus/><apply><times/><cn>2</cn><apply><minus/><ci>Y</ci><cn>10</cn></apply></apply></apply></apply></apply></apply><apply><times/><cn>1000</cn><ci>F</ci><apply><power/><apply><plus/><cn>1</cn><apply><divide/><ci>i</ci><cn>200</cn></apply></apply><apply><minus/><apply><times/><cn>2</cn><apply><minus/><ci>Y</ci><cn>10</cn></apply></apply></apply></apply></apply></apply><apply><plus/><cn>1</cn><apply><times/><apply><divide/><ci>i</ci><cn>100</cn></apply><apply><divide/><ci>n</ci><cn>360</cn></apply></apply></apply></apply></math>",
                        :correct_comments=>"Right answer.",
                        :unit_required=>false,
                        :partial_credit_tolerance=>0,
                        :incorrect_comments=>"Wrong.",
                        :formulas=>[{:formula => "<math><apply><times/><apply><power/><apply><times/><cn>10</cn><ci>F</ci></apply><apply><minus/><cn>1</cn></apply></apply><apply><plus/><apply><times/><cn>1000</cn><ci>F</ci><ci>r</ci><apply><power/><ci>i</ci><apply><minus/><cn>1</cn></apply></apply><apply><minus/><cn>1</cn><apply><power/><apply><plus/><cn>1</cn><apply><divide/><ci>i</ci><cn>200</cn></apply></apply><apply><minus/><apply><times/><cn>2</cn><apply><minus/><ci>Y</ci><cn>10</cn></apply></apply></apply></apply></apply></apply><apply><times/><cn>1000</cn><ci>F</ci><apply><power/><apply><plus/><cn>1</cn><apply><divide/><ci>i</ci><cn>200</cn></apply></apply><apply><minus/><apply><times/><cn>2</cn><apply><minus/><ci>Y</ci><cn>10</cn></apply></apply></apply></apply></apply></apply><apply><plus/><cn>1</cn><apply><times/><apply><divide/><ci>i</ci><cn>100</cn></apply><apply><divide/><ci>n</ci><cn>360</cn></apply></apply></apply></apply></math>"}],
                        :unit_case_sensitive=>false,
                        :points_possible=>10}

  CALCULATED_NUMERIC = {:migration_id=>"_154758_1",
                        :answers=>
                                [{:end=>4.0,
                                  :numerical_answer_type=>"range_answer",
                                  :start=>4.0,
                                  :exact=>4.0,
                                  :comments=>"",
                                  :weight=>100}],
                        :question_text=>"What is 10 - 6?<br>",
                        :correct_comments=>"Right.",
                        :incorrect_comments=>"Left",
                        :points_possible=>10.0,
                        :question_type=>"numerical_question",
                        :question_name=>""}

  ASSESSMENT = {:points_possible=>"237.0",
                :questions=>
                        [{:question_type=>"question_reference", :migration_id=>"_153086_1"},
                         {:question_type=>"question_reference", :migration_id=>"_152999_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153000_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153002_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153003_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153004_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153005_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153006_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153007_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153008_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153009_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153010_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153011_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153012_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153013_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153014_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153015_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153126_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153127_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153128_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153001_1"},
                         {:question_type=>"question_reference", :migration_id=>"_153271_1"}],
                :question_count=>22,
                :title=>"Blackboard 8 Export Test",
                :quiz_name=>"Blackboard 8 Export Test",
                :quiz_type=>"assignment",
                :migration_id=>"res00001",
                :grading=>
                        {
                                :migration_id=>"res00001",
                                :title=>"Blackboard 8 Export Test",
                                :points_possible=>"237.0",
                                :grade_type=>"numeric",
                                :due_date=>nil,
                                :weight=>nil
                        }
  }
end
end
