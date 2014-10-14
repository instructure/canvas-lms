# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::SubmissionGrader do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  context 'with course and quiz' do
  before(:once) do
    course
    @quiz = @course.quizzes.create!
  end

  describe ".score_question" do
    it "should score a multiple_choice_question" do
      qd = multiple_choice_question_data
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "1658" })).to eq(
        { :question_id => 1, :correct => true, :points => 50, :answer_id => 1658, :text => "1658" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "8544" })).to eq(
        { :question_id => 1, :correct => false, :points => 0, :answer_id => 8544, :text => "8544" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "5" })).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "5" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, {})).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "undefined_if_blank" => "1" })).to eq(
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
      )
    end

    it "should score a true_false_question" do
      qd = true_false_question_data
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "8950" })).to eq(
        { :question_id => 1, :correct => true, :points => 45, :answer_id => 8950, :text => "8950" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "8403" })).to eq(
        { :question_id => 1, :correct => false, :points => 0, :answer_id => 8403, :text => "8403" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "5" })).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "5" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, {})).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "undefined_if_blank" => "1" })).to eq(
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
      )
    end

    it "should score a short_answer_question (Fill In The Blank)" do
      qd = short_answer_question_data
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "stupid" })).to eq(
        { :question_id => 1, :correct => true, :points => 16.5, :answer_id => 7100, :text => "stupid" }
      )
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "   DUmB\n " })).to eq(
        { :question_id => 1, :correct => true, :points => 16.5, :answer_id => 2159, :text => "   DUmB\n " }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "short" })).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "short" }
      )

      # Blank answer from quiz taker should not match even if blank answer is on quiz (blanks created by default)
      qd_with_blank = short_answer_question_data_one_blank
      expect(Quizzes::SubmissionGrader.score_question(qd_with_blank, { "question_1" => "" })).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "" }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, {})).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "" }
      )

      # Preserve idea of "undefined" for when student wasn't asked the question (ie no response) as separate from
      # student was asked but didn't answer. Can happen when instructor adds question to a quiz that a student has
      # already started or completed.
      expect(Quizzes::SubmissionGrader.score_question(qd, { "undefined_if_blank" => "1" })).to eq(
        { :question_id => 1, :correct => 'undefined', :points => 0, :text => "" }
      )
    end

    it "should score an essay_question" do
      qd = essay_question_data
      text = "that's too <b>dang</b> hard! <script>alert(1)</script>"
      sanitized = "that's too <b>dang</b> hard! alert(1)"
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => text })).to eq(
        { :question_id => 1, :correct => "undefined", :points => 0, :text => sanitized }
      )

      expect(Quizzes::SubmissionGrader.score_question(qd, {})).to eq(
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
      )
    end

    it "should score a text_only_question" do
      expect(Quizzes::SubmissionGrader.score_question(text_only_question_data, {})).to eq(
        { :question_id => 3, :correct => "no_score", :points => 0, :text => "" }
      )
    end

    it "should score a matching_question" do
      q = matching_question_data

      # 1 wrong answer
      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_answer_7396" => "3562",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      expect(user_answer.delete(:points)).to be_within(0.01).of(41.67)
      expect(user_answer).to eq({
        :question_id => 1, :correct => "partial", :text => "",
        :answer_7396 => "3562",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      })

      # 1 wrong answer but no partial credit allowed
      user_answer = Quizzes::SubmissionGrader.score_question(q.merge(:allow_partial_credit => false), {
        "question_1_answer_7396" => "3562",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
        "blah" => "foo"
      })
      expect(user_answer).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_7396 => "3562",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      })

      # all wrong answers
      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_answer_7396" => "3562",
        "question_1_answer_6081" => "1500",
        "question_1_answer_4224" => "8513",
      })
      expect(user_answer).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_7396 => "3562",
        :answer_6081 => "1500",
        :answer_4224 => "8513",
        :answer_7397 => "",
        :answer_7398 => "",
        :answer_7399 => "",
      })

      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_answer_7396" => "6061",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      expect(user_answer).to eq({
        :question_id => 1, :correct => true, :points => 50, :text => "",
        :answer_7396 => "6061",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      })

      # selected a different answer but the text of that answer was the same
      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_answer_7396" => "1397",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      expect(user_answer).to eq({
        :question_id => 1, :correct => true, :points => 50, :text => "",
        :answer_7396 => "6061",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      })

      # no answer shouldn't be treated as a blank string, breaking undefined_if_blank
      expect(Quizzes::SubmissionGrader.score_question(q, { "undefined_if_blank" => "1" })).to eq({
        :question_id => 1, :correct => "undefined", :points => 0, :text => "",
        :answer_7396 => "",
        :answer_6081 => "",
        :answer_4224 => "",
        :answer_7397 => "",
        :answer_7398 => "",
        :answer_7399 => "",
      })
    end

    it "should score a numerical_question" do
      qd = numerical_question_data

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "3.2" })).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "3.2" })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "4" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "4", :answer_id => 9222 })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-4" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-4", :answer_id => 997 })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "4.05" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "4.05", :answer_id => 9370 })
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "4.10" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "4.10", :answer_id => 9370 })
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "3.90" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "3.90", :answer_id => 9370 })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-4.1" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-4.1", :answer_id => 5450 })
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-3.9" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-3.9", :answer_id => 5450 })
      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-4.05" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-4.05", :answer_id => 5450 })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "" })).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "" })

      expect(Quizzes::SubmissionGrader.score_question(qd, { :undefined_if_blank => "1" })).to eq({
        :question_id => 1, :correct => "undefined", :points => 0, :text => "" })

      # blank answer should not be treated as 0.0
      qd2 = qd.dup
      qd2["answers"] << { "exact" => 0, "numerical_answer_type" => "exact_answer", "margin" => 0, "weight" => 100, "id" => 1234 }
      expect(Quizzes::SubmissionGrader.score_question(qd2, { "question_1" => "" })).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "" })
    end

    it "should score a calculated_question" do
      qd = calculated_question_data

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-11.7" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-11.7", :answer_id => 6396 })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-11.68" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-11.68", :answer_id => 6396 })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-11.675" })).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "-11.675" })

      expect(Quizzes::SubmissionGrader.score_question(qd, {})).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "" })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "question_1" => "-11.72" })).to eq({
        :question_id => 1, :correct => true, :points => 26.2, :text => "-11.72", :answer_id => 6396 })
    end

    it "should score a multiple_answers_question" do
      qd = multiple_answers_question_data

      expect(Quizzes::SubmissionGrader.score_question(qd, {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "1",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "0",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "1",
        "question_1_answer_7381" => "0",
      })).to eq({
        :question_id => 1, :correct => true, :points => 50, :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "1",
        :answer_166  => "1",
        :answer_4739 => "0",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "1",
        :answer_7381 => "0",
      })

      # partial credit
      user_answer = Quizzes::SubmissionGrader.score_question(qd, {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "1",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "1",
        "question_1_answer_7381" => "0",
      })
      expect(user_answer.delete(:points)).to be_within(0.01).of(41.67)
      expect(user_answer).to eq({
        :question_id => 1, :correct => "partial", :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "1",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "1",
        :answer_7381 => "0",
      })

      user_answer = Quizzes::SubmissionGrader.score_question(qd.merge(:allow_partial_credit => false), {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "1",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "1",
        "question_1_answer_7381" => "0",
      })
      expect(user_answer).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "1",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "1",
        :answer_7381 => "0",
      })

      # checking one that shouldn't be checked, subtracts one correct answer's worth of points
      user_answer = Quizzes::SubmissionGrader.score_question(qd, {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "0",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "0",
        "question_1_answer_7381" => "0",
      })
      expect(user_answer.delete(:points)).to be_within(0.01).of(25.0)
      expect(user_answer).to eq({
        :question_id => 1, :correct => "partial", :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "0",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "0",
        :answer_7381 => "0",
      })

      # can't get less than 0
      user_answer = Quizzes::SubmissionGrader.score_question(qd, {
        "question_1_answer_9761" => "0",
        "question_1_answer_3079" => "1",
        "question_1_answer_5194" => "0",
        "question_1_answer_166"  => "0",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "0",
        "question_1_answer_7381" => "1",
      })
      expect(user_answer).to eq({
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_9761 => "0",
        :answer_3079 => "1",
        :answer_5194 => "0",
        :answer_166  => "0",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "0",
        :answer_7381 => "1",
      })

      # incorrect_dock allows a different value to be subtracted on incorrect answer
      # this isn't exposed in the UI anywhere yet, but the code supports it
      user_answer = Quizzes::SubmissionGrader.score_question(qd.merge(:incorrect_dock => 1.5), {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "0",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "0",
        "question_1_answer_7381" => "0",
      })
      expect(user_answer.delete(:points)).to be_within(0.01).of(31.83)
      expect(user_answer).to eq({
        :question_id => 1, :correct => "partial", :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "0",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "0",
        :answer_7381 => "0",
      })

      expect(Quizzes::SubmissionGrader.score_question(qd, { "undefined_if_blank" => "1" })).to eq(
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
      )
    end

    it "should score a multiple_dropdowns_question" do
      q = multiple_dropdowns_question_data

      user_answer = Quizzes::SubmissionGrader.score_question(q, { "question_1630873_4e6185159bea49c4d29047379b400ad5"=>"6994", "question_1630873_3f507e80e33ef092a02948a064433ec5"=>"5988", "question_1630873_78635a3709b540a59678c806b102d038"=>"9908", "question_1630873_657b11f1c17376f178c4d80c4c25d0ab"=>"1121", "question_1630873_02c8346333761ffe9bbddee7b1c5a537"=>"4390", "question_1630873_1865cbc77c83d7571ed8b3a108d11d3d"=>"7604", "question_1630873_94239fc44b4f8aaf36bd3596768f4816"=>"6955", "question_1630873_cd073d17d0d9558fb2be7d7bf9a1c840"=>"3353", "question_1630873_69d0969351d989767d7096f28daf7461"=>"3390"})
      expect(user_answer.delete(:points)).to be_within(0.01).of(0.44)
      expect(user_answer).to eq({
        :question_id => 1630873, :correct => "partial", :text => "",
        :answer_for_structure1 => 4390,
        :answer_id_for_structure1 => 4390,
        :answer_for_event1 => 3390,
        :answer_id_for_event1 => 3390,
        :answer_for_structure2 => 6955,
        :answer_id_for_structure2 => 6955,
        :answer_for_structure3 => 5988,
        :answer_id_for_structure3 => 5988,
        :answer_for_structure4 => 7604,
        :answer_id_for_structure4 => 7604,
        :answer_for_event2 => 3353,
        :answer_id_for_event2 => 3353,
        :answer_for_structure5 => 9908,
        :answer_id_for_structure5 => 9908,
        :answer_for_structure6 => 6994,
        :answer_id_for_structure6 => 6994,
        :answer_for_structure7 => 1121,
        :answer_id_for_structure7 => 1121,
      })

      user_answer = Quizzes::SubmissionGrader.score_question(q, { "question_1630873_4e6185159bea49c4d29047379b400ad5"=>"1883", "question_1630873_3f507e80e33ef092a02948a064433ec5"=>"5988", "question_1630873_78635a3709b540a59678c806b102d038"=>"878", "question_1630873_657b11f1c17376f178c4d80c4c25d0ab"=>"9570", "question_1630873_02c8346333761ffe9bbddee7b1c5a537"=>"1522", "question_1630873_1865cbc77c83d7571ed8b3a108d11d3d"=>"9532", "question_1630873_94239fc44b4f8aaf36bd3596768f4816"=>"1228", "question_1630873_cd073d17d0d9558fb2be7d7bf9a1c840"=>"599", "question_1630873_69d0969351d989767d7096f28daf7461"=>"5498"})
      expect(user_answer).to eq({
        :question_id => 1630873, :correct => false, :points => 0, :text => "",
        :answer_for_structure1 => 1522,
        :answer_id_for_structure1 => 1522,
        :answer_for_event1 => 5498,
        :answer_id_for_event1 => 5498,
        :answer_for_structure2 => 1228,
        :answer_id_for_structure2 => 1228,
        :answer_for_structure3 => 5988,
        :answer_id_for_structure3 => 5988,
        :answer_for_structure4 => 9532,
        :answer_id_for_structure4 => 9532,
        :answer_for_event2 => 599,
        :answer_id_for_event2 => 599,
        :answer_for_structure5 => 878,
        :answer_id_for_structure5 => 878,
        :answer_for_structure6 => 1883,
        :answer_id_for_structure6 => 1883,
        :answer_for_structure7 => 9570,
        :answer_id_for_structure7 => 9570,
      })

      user_answer = Quizzes::SubmissionGrader.score_question(q, { "question_1630873_4e6185159bea49c4d29047379b400ad5"=>"6994", "question_1630873_3f507e80e33ef092a02948a064433ec5"=>"7676", "question_1630873_78635a3709b540a59678c806b102d038"=>"9908", "question_1630873_657b11f1c17376f178c4d80c4c25d0ab"=>"1121", "question_1630873_02c8346333761ffe9bbddee7b1c5a537"=>"4390", "question_1630873_1865cbc77c83d7571ed8b3a108d11d3d"=>"7604", "question_1630873_94239fc44b4f8aaf36bd3596768f4816"=>"6955", "question_1630873_cd073d17d0d9558fb2be7d7bf9a1c840"=>"3353", "question_1630873_69d0969351d989767d7096f28daf7461"=>"3390"})
      expect(user_answer).to eq({
        :question_id => 1630873, :correct => true, :points => 0.5, :text => "",
        :answer_for_structure1 => 4390,
        :answer_id_for_structure1 => 4390,
        :answer_for_event1 => 3390,
        :answer_id_for_event1 => 3390,
        :answer_for_structure2 => 6955,
        :answer_id_for_structure2 => 6955,
        :answer_for_structure3 => 7676,
        :answer_id_for_structure3 => 7676,
        :answer_for_structure4 => 7604,
        :answer_id_for_structure4 => 7604,
        :answer_for_event2 => 3353,
        :answer_id_for_event2 => 3353,
        :answer_for_structure5 => 9908,
        :answer_id_for_structure5 => 9908,
        :answer_for_structure6 => 6994,
        :answer_id_for_structure6 => 6994,
        :answer_for_structure7 => 1121,
        :answer_id_for_structure7 => 1121,
      })
    end

    it "should score a fill_in_multiple_blanks_question" do
      q = fill_in_multiple_blanks_question_data
      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "control",
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "patrol",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "soul",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "toll",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "assplode",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "old",
      })
      expect(user_answer).to eq(
        { :question_id => 1, :correct => true, :points => 50.0, :text => "",
          :answer_for_answer1 => "control",
          :answer_id_for_answer1 => 3950,
          :answer_for_answer2 => "patrol",
          :answer_id_for_answer2 => 9181,
          :answer_for_answer3 => "soul",
          :answer_id_for_answer3 => 3733,
          :answer_for_answer4 => "toll",
          :answer_id_for_answer4 => 7829,
          :answer_for_answer5 => "assplode",
          :answer_id_for_answer5 => 5301,
          :answer_for_answer6 => "old",
          :answer_id_for_answer6 => 3367,
        }
      )

      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "control",
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "patrol",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "soul",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "toll",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "wut",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "old",
      })
      expect(user_answer.delete(:points)).to be_within(0.1).of(41.6)
      expect(user_answer).to eq(
        { :question_id => 1, :correct => "partial", :text => "",
          :answer_for_answer1 => "control",
          :answer_id_for_answer1 => 3950,
          :answer_for_answer2 => "patrol",
          :answer_id_for_answer2 => 9181,
          :answer_for_answer3 => "soul",
          :answer_id_for_answer3 => 3733,
          :answer_for_answer4 => "toll",
          :answer_id_for_answer4 => 7829,
          :answer_for_answer5 => "wut",
          :answer_id_for_answer5 => nil,
          :answer_for_answer6 => "old",
          :answer_id_for_answer6 => 3367,
        }
      )

      user_answer = Quizzes::SubmissionGrader.score_question(q, {
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "0",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "fail",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "wrong",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "wut",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "oh well",
      })
      expect(user_answer).to eq(
        { :question_id => 1, :correct => false, :points => 0, :text => "",
          :answer_for_answer1 => "",
          :answer_id_for_answer1 => nil,
          :answer_for_answer2 => "0",
          :answer_id_for_answer2 => nil,
          :answer_for_answer3 => "fail",
          :answer_id_for_answer3 => nil,
          :answer_for_answer4 => "wrong",
          :answer_id_for_answer4 => nil,
          :answer_for_answer5 => "wut",
          :answer_id_for_answer5 => nil,
          :answer_for_answer6 => "oh well",
          :answer_id_for_answer6 => nil,
        }
      )

      # one blank to fill in
      user_answer = Quizzes::SubmissionGrader.score_question(fill_in_multiple_blanks_question_one_blank_data, { "question_2_10ca8479f89652b254a5c6ec90ab9ab8" => " DUmB \n " })
      expect(user_answer).to eq(
        { :question_id => 2, :correct => true, :points => 3.75, :text => "",
          :answer_for_myblank => " DUmB \n ",
          :answer_id_for_myblank => 1235, }
      )

      user_answer = Quizzes::SubmissionGrader.score_question(fill_in_multiple_blanks_question_one_blank_data, { "question_2_10ca8479f89652b254a5c6ec90ab9ab8" => "wut" })
      expect(user_answer).to eq(
        { :question_id => 2, :correct => false, :points => 0, :text => "",
          :answer_for_myblank => "wut",
          :answer_id_for_myblank => nil, }
      )
    end

    it "should score an unknown question type" do
      # if a question with an invalid type makes it into the quiz data, we
      # score it as always 0 out of points_possible, rather than raise an error
      qd = {"name"=>"Question 1", "question_type"=>"Error", "assessment_question_id"=>nil, "migration_id"=>"i1234", "id"=>2, "points_possible"=>5.35, "question_name"=>"Question 1", "qti_error"=>"There was an error exporting an assessment question - No question type used when trying to parse a qti question", "question_text"=>"test1", "answers"=>[], "assessment_question_migration_id"=>"i1234"}.with_indifferent_access
      user_answer = Quizzes::SubmissionGrader.score_question(qd, {})
      expect(user_answer).to eq(
        { :question_id => 2, :correct => false, :points => 0, :text => "", }
      )
    end

    it "should not escape user responses in fimb questions" do
      course_with_student(:active_all => true)
      q = {:neutral_comments=>"",
       :position=>1,
       :question_name=>"Question 1",
       :correct_comments=>"",
       :answers=>
        [{:comments=>"",
          :blank_id=>"answer1",
          :weight=>100,
          :text=>"control",
          :id=>3950},
         {:comments=>"",
          :blank_id=>"answer1",
          :weight=>100,
          :text=>"controll",
          :id=>9177}],
       :points_possible=>50,
       :question_type=>"fill_in_multiple_blanks_question",
       :assessment_question_id=>7903,
       :name=>"Question 1",
       :question_text=>
        "<p><span>Ayo my quality [answer1]</p>",
       :id=>1,
       :incorrect_comments=>""}

       user_answer = Quizzes::SubmissionGrader.score_question(q, {
         "question_1_#{AssessmentQuestion.variable_id("answer1")}" => "<>&\""
       })
       expect(user_answer[:answer_for_answer1]).to eq "<>&\""
    end

    it "should not fail if fimb question doesn't have any answers" do
      course_with_student(:active_all => true)
      # @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      q = {:position=>1, :name=>"Question 1", :correct_comments=>"", :question_type=>"fill_in_multiple_blanks_question", :assessment_question_id=>7903, :incorrect_comments=>"", :neutral_comments=>"", :id=>1, :points_possible=>50, :question_name=>"Question 1", :answers=>[], :question_text=>"<p><span>Ayo my quality [answer1].</p>"}
      expect {
        Quizzes::SubmissionGrader.score_question(q, { "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "bleh" })
      }.not_to raise_error
    end
  end

  describe "formula questions" do
    before do
      @quiz = @course.quizzes.create!(:title => "formula quiz")
      @quiz.quiz_questions.create! :question_data => {
        :name => "Question",
        :question_type => "calculated_question",
        :answer_tolerance => 2.0,
        :formulas => [[0, "2*z"]],
        :variables => [{:scale => 0, :min => 1.0, :max => 10.0, :name => 'z'}],
        :answers => [{
          :weight => 100,
          :variables => [{:value => 2.0, :name => 'z'}],
          :answer_text => "4.0"
        }],
        :question_text => "2 * [z] is ?"
      }
      @quiz.generate_quiz_data(:persist => true)
    end

    it "should respect the answer_tolerance" do
      submission = @quiz.generate_submission(@user)
      submission.submission_data = {
        "question_#{@quiz.quiz_questions.first.id}" => 3.0, # off by 1
      }
      question = submission.quiz_data.first
      result = Quizzes::SubmissionGrader.score_question(question, submission.submission_data)
      expect(result[:correct]).to be_truthy
    end
  end

  describe "formula questions with percentage tolerance" do
    before do
      @quiz = @course.quizzes.create!(:title => "formula quiz")
      @quiz.quiz_questions.create! :question_data => {
        :name => "Question",
        :question_type => "calculated_question",
        :answer_tolerance => "10.0%",
        :formulas => [[0, "2*z"]],
        :variables => [{:scale => 0, :min => 1.0, :max => 10.0, :name => 'z'}],
        :answers => [{
          :weight => 100,
          :variables => [{:value => 2.0, :name => 'z'}],
          :answer_text => "4.0"
        }],
        :question_text => "2 * [z] is ?"
      }
      @quiz.generate_quiz_data(:persist => true)
    end

    it "should respect the answer_tolerance" do
      submission = @quiz.generate_submission(@user)
      submission.submission_data = {
        "question_#{@quiz.quiz_questions.first.id}" => 4.4, # off by 10%
      }
      question = submission.quiz_data.first
      result = Quizzes::SubmissionGrader.score_question(question, submission.submission_data)
      expect(result[:correct]).to be_truthy
    end
  end

  end
end

