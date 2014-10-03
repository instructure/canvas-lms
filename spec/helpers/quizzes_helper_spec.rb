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
  include ERB::Util

  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe "#needs_unpublished_warning" do
    before :once do
      course_with_teacher
    end

    it "is false if quiz not manageable" do
      quiz = Quizzes::Quiz.new(:context => @course)

      def can_publish(quiz); false; end
      needs_unpublished_warning?(quiz, User.new).should be_false
    end

    it "is false if quiz is available with no unpublished changes" do
      quiz = Quizzes::Quiz.new(:context => @course)
      quiz.workflow_state = 'available'
      quiz.last_edited_at = 10.minutes.ago
      quiz.published_at   = Time.now

      def can_publish(quiz); true; end
      needs_unpublished_warning?(quiz, User.new).should be_false
    end

    it "is true if quiz is not available" do
      quiz = Quizzes::Quiz.new(:context => @course)
      quiz.workflow_state = 'created'

      def can_publish(quiz); true; end
      needs_unpublished_warning?(quiz, User.new).should be_true
    end

    it "is true if quiz has unpublished changes" do
      quiz = Quizzes::Quiz.new(:context => @course)
      quiz.workflow_state = 'available'
      quiz.last_edited_at = Time.now
      quiz.published_at   = 10.minutes.ago

      def can_publish(quiz); true; end
      needs_unpublished_warning?(quiz, User.new).should be_true
    end
  end

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

  context 'fill_in_multiple_blanks_question' do
    before(:each) do
      @question_text = %q|<input name="question_1_1813d2a7223184cf43e19db6622df40b" 'value={{question_1}}' />|
      @answer_list = []
      @answers = []

      def user_content(stuff); stuff; end # mock #user_content
    end

    it 'should extract the answers by blank' do
      @answer_list = [{ blank_id: 'color', answer: 'red' }]

      html = fill_in_multiple_blanks_question(
        :question => {:question_text => @question_text},
        :answer_list => @answer_list,
        :answers => @answers
      )

      html.should == %q|<input name="question_1_1813d2a7223184cf43e19db6622df40b" 'value=red' readonly="readonly" aria-label='Fill in the blank, read surrounding text' />|
    end

    it 'should sanitize user input' do
      malicious_answer_list = [{
        blank_id: 'color',
        answer: %q|'><script>alert('ha!')</script><img|
      }]

      html = fill_in_multiple_blanks_question(
        :question => {:question_text => @question_text},
        :answer_list => malicious_answer_list,
        :answers => @answers
      )

      html.should == %q|<input name="question_1_1813d2a7223184cf43e19db6622df40b" 'value=&#x27;&gt;&lt;script&gt;alert(&#x27;ha!&#x27;)&lt;/script&gt;&lt;img' readonly="readonly" aria-label='Fill in the blank, read surrounding text' />|
      html.should be_html_safe
    end

    it 'should add an appropriate label' do
      html = fill_in_multiple_blanks_question(
        :question => {:question_text => @question_text},
        :answer_list => @answer_list,
        :answers => @answers
      )

      html.should =~ /aria\-label/
      html.should =~ /Fill in the blank/
    end
    it 'should handle equation img tags in the question text' do
      broken_question_text = "\"<p>Rubisco is a <input class='question_input' type='text' autocomplete='off' style='width: 120px;' name=\\\"question_8_26534e6c8737f63335d5d98ca4136d09\\\" value='{{question_8_26534e6c8737f63335d5d98ca4136d09}}' > responsible for the first enzymatic step of carbon <input class='question_input' type='text' autocomplete='off' style='width: 120px;' name='question_8_f8e302199c03689d87c52e942b56e1f4' value='{{question_8_f8e302199c03689d87c52e942b56e1f4}}' >. <br><br>equation here: <img class=\\\"equation_image\\\" title=\\\"\\sum\\frac{k}{l}\\\" src=\\\"/equation_images/%255Csum%255Cfrac%257Bk%257D%257Bl%257D\\\" alt=\\\"\\sum\\frac{k}{l}\\\"></p>\""
      @answer_list = [
        { blank_id: 'kindof', answer: 'protein'},
        {blank_id: 'role', answer: 'fixing'}
      ]
      html = fill_in_multiple_blanks_question(
        question: {question_text: broken_question_text},
        answer_list: @answer_list,
        answers: @answers
      )
      html.should =~ /"readonly"/
      html.should =~ /value='fixing'/
      html.should =~ /value='protein'/
    end
  end

  context "multiple_dropdowns_question" do
    before do
      def user_content(stuff); stuff; end # mock #user_content
    end

    it "should select the user's answer" do
      html = multiple_dropdowns_question(question: { question_text: "some <select name='question_4'><option value='val'>val</option></select>"},
                                         answer_list: ['val'])
      html.should == "some <select name='question_4'><option value='val' selected>val</option></select>"
      html.should be_html_safe
    end
  end

  describe "#quiz_edit_text" do

    it "returns correct string for survey" do
      quiz = stub(:survey? => true)
      quiz_edit_text(quiz).should == "Edit Survey"
    end

    it "returns correct string for quiz" do
      quiz = stub(:survey? => false)
      quiz_edit_text(quiz).should == "Edit Quiz"
    end
  end

  describe "#quiz_delete_text" do

    it "returns correct string for survey" do
      quiz = stub(:survey? => true)
      quiz_delete_text(quiz).should == "Delete Survey"
    end

    it "returns correct string for quiz" do
      quiz = stub(:survey? => false)
      quiz_delete_text(quiz).should == "Delete Quiz"
    end
  end

  describe "#score_affected_by_regrade" do
    it "returns true if kept score differs from score before regrade" do
      submission = stub(:score_before_regrade => 5, :kept_score => 10, :score => 5)
      score_affected_by_regrade?(submission).should be_true
    end

    it "returns false if kept score equals score before regrade" do
      submission = stub(:score_before_regrade => 5, :kept_score => 5, :score => 0)
      score_affected_by_regrade?(submission).should be_false
    end
  end

  describe "#answer_title" do
    it "builds title if answer is selected" do
      title = answer_title('foo', true, false, false)
      title.should == "title=\"foo. You selected this answer.\""
    end

    it "builds title if answer is correct" do
      title = answer_title('foo', false, true, true)
      title.should == "title=\"foo. This was the correct answer.\""
    end

    it "returns nil if not selected or correct" do
      title = answer_title('foo', false, false, false)
      title.should be_nil
    end
  end

  describe '#render_correct_answer_protection' do
    it 'should provide a useful message when "no"' do
      quiz = stub({
        show_correct_answers: false,
        show_correct_answers_at: nil,
        hide_correct_answers_at: nil
      })

      message = render_correct_answer_protection(quiz)
      message.should =~ /are hidden/
    end

    it 'should provide nothing when "yes"' do
      quiz = stub({
        show_correct_answers: true,
        show_correct_answers_at: nil,
        hide_correct_answers_at: nil
      })

      message = render_correct_answer_protection(quiz)
      message.should == nil
    end

    it 'should provide a useful message, and an availability date, when "show at" is set' do
      quiz = stub({
        show_correct_answers: true,
        show_correct_answers_at: 1.day.from_now,
        hide_correct_answers_at: nil
      })

      message = render_correct_answer_protection(quiz)
      message.should =~ /will be available/
    end

    it 'should provide a useful message, and a date, when "hide at" is set' do
      quiz = stub({
        show_correct_answers: true,
        show_correct_answers_at: nil,
        hide_correct_answers_at: 1.day.from_now
      })

      message = render_correct_answer_protection(quiz)
      message.should =~ /are available until/
    end
  end

  context "#point_value_for_input" do
    let(:user_answer) { @user_answer }
    let(:question) { { points_possible: 5 } }
    let(:quiz) { @quiz }

    before do
      @quiz = stub(quiz_type: 'graded_survey')
      @user_answer = { correct: 'undefined', points: 5 }
    end

    it "returns user_answer[:points] if correct is true/false" do
      [true, false].each do |bool|
        user_answer[:correct] = bool
        point_value_for_input(user_answer, question).should == user_answer[:points]
      end
    end

    it "returns -- if quiz is practice quiz or assignment" do
      ['assignment', 'practice_quiz'].each do |quiz_type|
        @quiz.expects(:quiz_type).returns quiz_type
        point_value_for_input(user_answer, question).should == "--"
      end
    end

    it "returns points possible for the question if (un)graded survey" do
      ['survey', 'graded_survey'].each do |quiz_type|
        @quiz.expects(:quiz_type).returns quiz_type
        point_value_for_input(user_answer, question).should ==
          question[:points_possible]
      end
    end
  end
end
