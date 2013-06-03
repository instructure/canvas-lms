# encoding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuizzesHelper do
  include ApplicationHelper
  include QuizzesHelper

  describe "#attachment_id_for" do

    it "returns the attachment id if attachment exists" do
      question = {:id => 1}
      @attachments = { 1 => {:id => "11"} }
      @stored_params = { "question_1" => ["1"]}
      attachment_id_for(question).should == "11"
    end

    it "returns empty string when no attachments stored" do

      question = {:id => 1}
      @stored_params = {}
      @attachments = {}
      attachment_id_for(question).should == nil
    end
  end

  context 'render_score' do
    it 'should render nil scores' do
      render_score(nil).should == '_'
    end

    it 'should render non-nil scores' do
      render_score(1).should == '1'
      render_score(100).should == '100'
      render_score(1.123).should == '1.12'
      render_score(1000.45166).should == '1000.45'
      render_score(1000.45966).should == '1000.46'
      render_score('100').should == '100'
      render_score('1.43').should == '1.43'
    end

    it 'should remove trailing zeros' do
      render_score(1.20000000).should == '1.2'
      render_score(0.10340000, 5).should == '0.1034'
    end

    it 'should remove trailing zeros and decimal point' do
      render_score(0.00000000).should == '0'
      render_score(1.00000000).should == '1'
      render_score(100.0).should == '100'
    end
  end

  context 'render_quiz_type' do
    it 'should render a humanized quiz type string' do
      render_quiz_type('practice_quiz').should == "Practice Quiz"
      render_quiz_type('assignment').should == "Graded Quiz"
      render_quiz_type('graded_survey').should == "Graded Survey"
      render_quiz_type('survey').should == "Ungraded Survey"
    end

    it 'should return nil for an unrecognized quiz_type' do
      render_quiz_type(nil).should be_nil
      render_quiz_type('made_up_quiz_type').should be_nil
    end
  end

  context 'render_score_to_keep' do
    it 'should render which score to keep when passed in a scoring_policy option' do
      render_score_to_keep('keep_highest').should == "Highest"
      render_score_to_keep('keep_latest').should == "Latest"
    end

    it 'should return nil for an unrecognized scoring_policy' do
      render_score_to_keep(nil).should be_nil
      render_score_to_keep('made_up_scoring_policy').should be_nil
    end
  end

  context 'render_show_responses' do
    it "should answer 'Let Students See Quiz Responses?' when passed a hide_results option" do
      render_show_responses('always').should == "No"
      render_show_responses('until_after_last_attempt').should == "After Last Attempt"
      render_show_responses(nil).should == "Always"
    end

    it "should return nil for an unrecognized hide_results value" do
      render_show_responses('made_up_hide_results').should be_nil
    end
  end

  context 'score_out_of_points_possible' do
    it 'should show single digit scores' do
      score_out_of_points_possible(1, 5).should == "1 out of 5"
      score_out_of_points_possible(0, 9).should == "0 out of 9"
    end

    it 'should show 2-decimal precision if necessary' do
      score_out_of_points_possible(0.66666666666, 1).should == "0.67 out of 1"
      score_out_of_points_possible(5.23333333333, 10.0).should == "5.23 out of 10"
    end

    it 'should be wrapped by a span when a CSS class, id, or style is given' do
      score_out_of_points_possible(1.5, 3, :class => "score_value").should == \
        '<span class="score_value">1.5</span> out of 3'
      score_out_of_points_possible(1.5, 3, :id => "score").should == \
        '<span id="score">1.5</span> out of 3'
      score_out_of_points_possible(1.5, 3, :style => "width:100%").should == \
        '<span style="width:100%">1.5</span> out of 3'
    end
  end

  context 'duration_in_minutes' do
    it 'should work in russian when count == 1' do
      I18n.locale = "ru"
      duration_in_minutes(60.6).should == "1 минута"
    end
  end

  context 'fill_in_multiple_blanks_question' do
    it 'should sanitize user input' do
      def user_content(stuff); stuff; end

      question_text = %q|<input name="question_1" 'value={{question_1}}' />|
      html = fill_in_multiple_blanks_question(
        :question => {:question_text => question_text},
        :answer_list => [%q|'><script>alert('ha!')</script><img|],
        :answers => []
      )

      html.should == %q|<input name="question_1" 'value=&#39;&gt;&lt;script&gt;alert(&#39;ha!&#39;)&lt;/script&gt;&lt;img' readonly="readonly" />|
    end
  end

end
