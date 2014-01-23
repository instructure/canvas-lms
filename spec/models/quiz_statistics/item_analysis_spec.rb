require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/item_analysis/common.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

describe QuizStatistics::ItemAnalysis do
  let(:report_type) { 'item_analysis' }
  include_examples "QuizStatistics::Report"
end

describe QuizStatistics::ItemAnalysis do

  before(:each) do
    simple_quiz_with_submissions(
      %w{T D F A},
      %w{T B T A}, # 2 wrong
      %w{T D F A}, # correct
      %w{F A T C}, # 4 wrong
      %w{T D F B}, # 1 wrong
      %w{T D F A}, # correct
      %w{F D}      # 3 wrong
    )
    @quiz_statistics = @quiz.statistics_csv('item_analysis')
  end

  it "should generate a csv" do
    qs = @quiz.active_quiz_questions
    csv = @quiz_statistics.csv_attachment.open.read
    stats = CSV.parse(csv)
    stats[0].should == ["Question Id" , "Question Title" , "Answered Student Count" , "Top Student Count" , "Middle Student Count" , "Bottom Student Count" , "Quiz Question Count" , "Correct Student Count" , "Wrong Student Count" , "Correct Student Ratio" , "Wrong Student Ratio" , "Correct Top Student Count" , "Correct Middle Student Count" , "Correct Bottom Student Count" , "Variance"            , "Standard Deviation"  , "Difficulty Index"   , "Alpha"              , "Point Biserial of Correct" , "Point Biserial of Distractor 2" , "Point Biserial of Distractor 3" , "Point Biserial of Distractor 4"]
    stats[1].should == [qs[0].id.to_s , "Question text"  , "6"                      , "2"                 , "2"                    , "2"                    , "4"                   , "4"                     , "2"                   , "0.6666666666666666"    , "0.3333333333333333"  , "2"                         , "2"                            , "0"                            , "0.22222222222222224" , "0.4714045207910317"  , "0.6666666666666666" , "N/A" , "0.8696263565463043"        , "-0.8696263565463043"            , nil                              , nil]
    stats[2].should == [qs[1].id.to_s , "Question text"  , "6"                      , "2"                 , "2"                    , "2"                    , "4"                   , "4"                     , "2"                   , "0.6666666666666666"    , "0.3333333333333333"  , "2"                         , "1"                            , "1"                            , "0.22222222222222224" , "0.4714045207910317"  , "0.6666666666666666" , "N/A" , "0.6324555320336759"        , "-0.7"                           , "-0.09999999999999999"           , nil]
    stats[3].should == [qs[2].id.to_s , "Question text"  , "5"                      , "2"                 , "2"                    , "1"                    , "4"                   , "3"                     , "2"                   , "0.6"                   , "0.4"                 , "2"                         , "1"                            , "0"                            , "0.24000000000000005" , "0.48989794855663565" , "0.6"                , "N/A" , "0.8728715609439694"        , "-0.8728715609439694"            , nil                              , nil]
    stats[4].should == [qs[3].id.to_s , "Question text"  , "5"                      , "2"                 , "2"                    , "1"                    , "4"                   , "3"                     , "2"                   , "0.6"                   , "0.4"                 , "2"                         , "1"                            , "0"                            , "0.24000000000000005" , "0.48989794855663565" , "0.6"                , "N/A" , "0.6000991981489792"        , "0.13363062095621223"            , "-0.8685990362153794"            , nil]
  end

end
