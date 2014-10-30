require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/item_analysis/common.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

require 'csv'

describe Quizzes::QuizStatistics::ItemAnalysis do

  let(:report_type) { 'item_analysis' }
  include_examples "Quizzes::QuizStatistics::Report"

  before(:once) do
    simple_quiz_with_submissions(
      %w{T D F A},
      %w{T B T A}, # 2 wrong
      %w{T D F A}, # correct
      %w{F A T C}, # 4 wrong
      %w{T D F B}, # 1 wrong
      %w{T D F A}, # correct
      %w{F D}      # 3 wrong
    )
  end

  it "should generate a csv" do
    quiz_statistics = @quiz.statistics_csv('item_analysis')
    qs = @quiz.active_quiz_questions
    csv = quiz_statistics.csv_attachment.open.read
    stats = CSV.parse(csv)
    expect(stats[0]).to eq ["Question Id" , "Question Title" , "Answered Student Count" , "Top Student Count" , "Middle Student Count" , "Bottom Student Count" , "Quiz Question Count" , "Correct Student Count" , "Wrong Student Count" , "Correct Student Ratio" , "Wrong Student Ratio" , "Correct Top Student Count" , "Correct Middle Student Count" , "Correct Bottom Student Count" , "Variance"            , "Standard Deviation"  , "Difficulty Index"   , "Alpha"              , "Point Biserial of Correct" , "Point Biserial of Distractor 2" , "Point Biserial of Distractor 3" , "Point Biserial of Distractor 4"]
    expect(stats[1]).to eq [qs[0].id.to_s , "Question text"  , "6"                      , "2"                 , "2"                    , "2"                    , "4"                   , "4"                     , "2"                   , "0.6666666666666666"    , "0.3333333333333333"  , "2"                         , "2"                            , "0"                            , "0.22222222222222224" , "0.4714045207910317"  , "0.6666666666666666" , "N/A" , "0.8696263565463043"        , "-0.8696263565463043"            , nil                              , nil]
    expect(stats[2]).to eq [qs[1].id.to_s , "Question text"  , "6"                      , "2"                 , "2"                    , "2"                    , "4"                   , "4"                     , "2"                   , "0.6666666666666666"    , "0.3333333333333333"  , "2"                         , "1"                            , "1"                            , "0.22222222222222224" , "0.4714045207910317"  , "0.6666666666666666" , "N/A" , "0.6324555320336759"        , "-0.7"                           , "-0.09999999999999999"           , nil]
    expect(stats[3]).to eq [qs[2].id.to_s , "Question text"  , "5"                      , "2"                 , "2"                    , "1"                    , "4"                   , "3"                     , "2"                   , "0.6"                   , "0.4"                 , "2"                         , "1"                            , "0"                            , "0.24000000000000005" , "0.48989794855663565" , "0.6"                , "N/A" , "0.8728715609439694"        , "-0.8728715609439694"            , nil                              , nil]
    expect(stats[4]).to eq [qs[3].id.to_s , "Question text"  , "5"                      , "2"                 , "2"                    , "1"                    , "4"                   , "3"                     , "2"                   , "0.6"                   , "0.4"                 , "2"                         , "1"                            , "0"                            , "0.24000000000000005" , "0.48989794855663565" , "0.6"                , "N/A" , "0.6000991981489792"        , "0.13363062095621223"            , "-0.8685990362153794"            , nil]
  end

  it 'should generate' do
    qs = @quiz.active_quiz_questions
    stats = @quiz.current_statistics_for('item_analysis')
    items = stats.report.generate

    item = items[0].with_indifferent_access
    point_biserials = item.delete(:point_biserials)
    precision = 0.0001

    expect(item[:question_id]).to eq qs[0].id
    expect(item[:answered_student_count]).to eq 6
    expect(item[:top_student_count]).to eq 2
    expect(item[:middle_student_count]).to eq 2
    expect(item[:bottom_student_count]).to eq 2
    expect(item[:correct_student_count]).to eq 4
    expect(item[:incorrect_student_count]).to eq 2
    expect(item[:correct_student_ratio]).to be_within(precision).of(0.6666666666666666)
    expect(item[:incorrect_student_ratio]).to be_within(precision).of(0.3333333333333333)
    expect(item[:correct_top_student_count]).to eq 2
    expect(item[:correct_middle_student_count]).to eq 2
    expect(item[:correct_bottom_student_count]).to eq 0
    expect(item[:variance]).to be_within(precision).of(0.22222222222222224)
    expect(item[:stdev]).to be_within(precision).of(0.4714045207910317)
    expect(item[:difficulty_index]).to be_within(precision).of(0.6666666666666666)
    expect(item[:alpha]).to eq nil

    answer_ids = stats.report.send(:summary_stats_for_quiz).sorted_items[0].answers

    expect(point_biserials.length).to eq 2 # this is a true/false question

    expect(point_biserials[0][:answer_id]).to eq answer_ids[0]
    expect(point_biserials[0][:point_biserial]).to be_within(precision).of(0.8696263565463043)
    expect(point_biserials[0][:correct]).to eq true
    expect(point_biserials[0][:distractor]).to eq false

    expect(point_biserials[1][:answer_id]).to eq answer_ids[1]
    expect(point_biserials[1][:point_biserial]).to be_within(precision).of(-0.8696263565463043)
    expect(point_biserials[1][:correct]).to eq false
    expect(point_biserials[1][:distractor]).to eq true
  end
end
