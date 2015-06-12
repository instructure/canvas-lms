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

  describe "#needs_unpublished_warning" do
    before :once do
      course_with_teacher
    end

    it "is false if quiz not manageable" do
      quiz = Quizzes::Quiz.new(:context => @course)

      def can_publish(quiz); false; end
      expect(needs_unpublished_warning?(quiz, User.new)).to be_falsey
    end

    it "is false if quiz is available with no unpublished changes" do
      quiz = Quizzes::Quiz.new(:context => @course)
      quiz.workflow_state = 'available'
      quiz.last_edited_at = 10.minutes.ago
      quiz.published_at   = Time.now

      def can_publish(quiz); true; end
      expect(needs_unpublished_warning?(quiz, User.new)).to be_falsey
    end

    it "is true if quiz is not available" do
      quiz = Quizzes::Quiz.new(:context => @course)
      quiz.workflow_state = 'created'

      def can_publish(quiz); true; end
      expect(needs_unpublished_warning?(quiz, User.new)).to be_truthy
    end

    it "is true if quiz has unpublished changes" do
      quiz = Quizzes::Quiz.new(:context => @course)
      quiz.workflow_state = 'available'
      quiz.last_edited_at = Time.now
      quiz.published_at   = 10.minutes.ago

      def can_publish(quiz); true; end
      expect(needs_unpublished_warning?(quiz, User.new)).to be_truthy
    end
  end

  describe "#attachment_id_for" do

    it "returns the attachment id if attachment exists" do
      question = {:id => 1}
      @attachments = { 1 => {:id => "11"} }
      @stored_params = { "question_1" => ["1"]}
      expect(attachment_id_for(question)).to eq "11"
    end

    it "returns empty string when no attachments stored" do

      question = {:id => 1}
      @stored_params = {}
      @attachments = {}
      expect(attachment_id_for(question)).to eq nil
    end
  end

  context 'render_score' do
    it 'should render nil scores' do
      expect(render_score(nil)).to eq '_'
    end

    it 'should render non-nil scores' do
      expect(render_score(1)).to eq '1'
      expect(render_score(100)).to eq '100'
      expect(render_score(1.123)).to eq '1.12'
      expect(render_score(1000.45166)).to eq '1000.45'
      expect(render_score(1000.45966)).to eq '1000.46'
      expect(render_score('100')).to eq '100'
      expect(render_score('1.43')).to eq '1.43'
    end

    it 'should remove trailing zeros' do
      expect(render_score(1.20000000)).to eq '1.2'
      expect(render_score(0.10340000, 5)).to eq '0.1034'
    end

    it 'should remove trailing zeros and decimal point' do
      expect(render_score(0.00000000)).to eq '0'
      expect(render_score(1.00000000)).to eq '1'
      expect(render_score(100.0)).to eq '100'
    end
  end

  context 'render_quiz_type' do
    it 'should render a humanized quiz type string' do
      expect(render_quiz_type('practice_quiz')).to eq "Practice Quiz"
      expect(render_quiz_type('assignment')).to eq "Graded Quiz"
      expect(render_quiz_type('graded_survey')).to eq "Graded Survey"
      expect(render_quiz_type('survey')).to eq "Ungraded Survey"
    end

    it 'should return nil for an unrecognized quiz_type' do
      expect(render_quiz_type(nil)).to be_nil
      expect(render_quiz_type('made_up_quiz_type')).to be_nil
    end
  end

  context 'render_score_to_keep' do
    it 'should render which score to keep when passed in a scoring_policy option' do
      expect(render_score_to_keep('keep_highest')).to eq "Highest"
      expect(render_score_to_keep('keep_latest')).to eq "Latest"
    end

    it 'should return nil for an unrecognized scoring_policy' do
      expect(render_score_to_keep(nil)).to be_nil
      expect(render_score_to_keep('made_up_scoring_policy')).to be_nil
    end
  end

  context 'render_show_responses' do
    it "should answer 'Let Students See Quiz Responses?' when passed a hide_results option" do
      expect(render_show_responses('always')).to eq "No"
      expect(render_show_responses('until_after_last_attempt')).to eq "After Last Attempt"
      expect(render_show_responses(nil)).to eq "Always"
    end

    it "should return nil for an unrecognized hide_results value" do
      expect(render_show_responses('made_up_hide_results')).to be_nil
    end
  end

  context 'score_out_of_points_possible' do
    it 'should show single digit scores' do
      expect(score_out_of_points_possible(1, 5)).to eq "1 out of 5"
      expect(score_out_of_points_possible(0, 9)).to eq "0 out of 9"
    end

    it 'should show 2-decimal precision if necessary' do
      expect(score_out_of_points_possible(0.66666666666, 1)).to eq "0.67 out of 1"
      expect(score_out_of_points_possible(5.23333333333, 10.0)).to eq "5.23 out of 10"
    end

    it 'should be wrapped by a span when a CSS class, id, or style is given' do
      expect(score_out_of_points_possible(1.5, 3, :class => "score_value")).to eq( \
        '<span class="score_value">1.5</span> out of 3'
      )
      expect(score_out_of_points_possible(1.5, 3, :id => "score")).to eq( \
        '<span id="score">1.5</span> out of 3'
      )
      expect(score_out_of_points_possible(1.5, 3, :style => "width:100%")).to eq( \
        '<span style="width:100%">1.5</span> out of 3'
      )
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

      expect(html).to eq %q|<input name="question_1_1813d2a7223184cf43e19db6622df40b" 'value=red' readonly="readonly" aria-label='Fill in the blank, read surrounding text' />|
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

      expect(html).to eq %q|<input name="question_1_1813d2a7223184cf43e19db6622df40b" 'value=&#x27;&gt;&lt;script&gt;alert(&#x27;ha!&#x27;)&lt;/script&gt;&lt;img' readonly="readonly" aria-label='Fill in the blank, read surrounding text' />|
      expect(html).to be_html_safe
    end

    it 'should add an appropriate label' do
      html = fill_in_multiple_blanks_question(
        :question => {:question_text => @question_text},
        :answer_list => @answer_list,
        :answers => @answers
      )

      expect(html).to match /aria\-label/
      expect(html).to match /Fill in the blank/
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
      expect(html).to match /"readonly"/
      expect(html).to match /value='fixing'/
      expect(html).to match /value='protein'/
    end
    it "should sanitize the answer blocks in the noisy question data" do
      broken_question_text = "<p><span>\"Roses are <input\n class='question_input'\n type='text'\n autocomplete='off'\n style='width: 120px;'\n name='question_244_ec9a1c7e5a9f3a6278e9055d8dec00f0'\n value='{{question_244_ec9a1c7e5a9f3a6278e9055d8dec00f0}}' />\n, violets are <input\n class='question_input'\n type='text'\n autocomplete='off'\n style='width: 120px;'\n name='question_244_01731fa53c4cf2f32e893d5c3dbae9c1'\n value='{{question_244_01731fa53c4cf2f32e893d5c3dbae9c1}}' />\n\")</span></p>"
      html = fill_in_multiple_blanks_question(
        question: {question_text: ActiveSupport::SafeBuffer.new(broken_question_text)},
        answer_list: [
          {:blank_id=>"color1", :answer=>"red"},
          {:blank_id=>"color2", :answer=>"black"}
        ], answers: @answers
      )
      expect(html).not_to match "{{"
    end
  end

  context "multiple_dropdowns_question" do
    before do
      def user_content(stuff); stuff; end # mock #user_content
    end

    it "should select the user's answer" do
      html = multiple_dropdowns_question(question: { question_text: 'some <select class="question_input" name="question_4"><option value="val">val</option></select>'},
                                         answer_list: ['val'])
      expect(html).to eq 'some <select class="question_input" name="question_4"><option value="val" selected>val</option></select>'
      expect(html).to be_html_safe
    end

    it "should not blow up if the user's answer isn't there" do
      html = multiple_dropdowns_question(question: { question_text: 'some <select class="question_input" name="question_4"><option value="other_val">val</option></select>'},
                                         answer_list: ['val'])
      expect(html).to eq 'some <select class="question_input" name="question_4"><option value="other_val">val</option></select>'
      expect(html).to be_html_safe
    end
  end

  describe "#quiz_edit_text" do

    it "returns correct string for survey" do
      quiz = stub(:survey? => true)
      expect(quiz_edit_text(quiz)).to eq "Edit Survey"
    end

    it "returns correct string for quiz" do
      quiz = stub(:survey? => false)
      expect(quiz_edit_text(quiz)).to eq "Edit Quiz"
    end
  end

  describe "#quiz_delete_text" do

    it "returns correct string for survey" do
      quiz = stub(:survey? => true)
      expect(quiz_delete_text(quiz)).to eq "Delete Survey"
    end

    it "returns correct string for quiz" do
      quiz = stub(:survey? => false)
      expect(quiz_delete_text(quiz)).to eq "Delete Quiz"
    end
  end

  describe "#score_affected_by_regrade" do
    it "returns true if kept score differs from score before regrade" do
      submission = stub(:score_before_regrade => 5, :kept_score => 10, :score => 5)
      expect(score_affected_by_regrade?(submission)).to be_truthy
    end

    it "returns false if kept score equals score before regrade" do
      submission = stub(:score_before_regrade => 5, :kept_score => 5, :score => 0)
      expect(score_affected_by_regrade?(submission)).to be_falsey
    end
  end

  describe "#answer_title" do
    it "builds title if answer is selected" do
      title = answer_title('foo', true, false, false)
      expect(title).to eq "title=\"foo. You selected this answer.\""
    end

    it "builds title if answer is correct" do
      title = answer_title('foo', false, true, true)
      expect(title).to eq "title=\"foo. This was the correct answer.\""
    end

    it "returns nil if not selected or correct" do
      title = answer_title('foo', false, false, false)
      expect(title).to be_nil
    end
  end

  describe "#render_show_correct_answers" do
    context "show_correct_answers is false" do
      it 'shows No' do
        quiz = stub({show_correct_answers: false})
        expect(render_show_correct_answers(quiz)).to eq "No"
      end
    end

    context "show_correct_answers is true, but nothing else is set" do
      it 'shows Immediately' do
        quiz = stub({
          show_correct_answers: true,
          show_correct_answers_at: nil,
          hide_correct_answers_at: nil,
          show_correct_answers_last_attempt: false
        })
        expect(render_show_correct_answers(quiz)).to eq "Immediately"
      end
    end

    context "show_correct_answers_last_attempt is true" do
      it 'shows After Last Attempt' do
        quiz = stub({
          show_correct_answers: true,
          show_correct_answers_at: nil,
          hide_correct_answers_at: nil,
          show_correct_answers_last_attempt: true
        })
        expect(render_show_correct_answers(quiz)).to eq "After Last Attempt"
      end
    end

    context "show_correct_answers_at is set" do
      it 'shows date of ' do
        time = 1.day.from_now
        quiz = stub({
          show_correct_answers: true,
          show_correct_answers_at: time,
          hide_correct_answers_at: nil
        })
        expect(render_show_correct_answers(quiz)).to eq "After #{datetime_string(time)}"
      end
    end

    context "hide_correct_answers_at is set" do
      it 'shows date of ' do
        time = 1.day.from_now
        quiz = stub({
          show_correct_answers: true,
          show_correct_answers_at: nil,
          hide_correct_answers_at: time,
        })
        expect(render_show_correct_answers(quiz)).to eq "Until #{datetime_string(time)}"
      end
    end

    context "show_correct_answers_at and hide_correct_answers_at are set" do
      it 'shows date of ' do
        time = 1.day.from_now
        time2 = 1.week.from_now

        quiz = stub({
          show_correct_answers: true,
          show_correct_answers_at: time,
          hide_correct_answers_at: time2,
        })
        expect(render_show_correct_answers(quiz)).to eq "From #{datetime_string(time)} to #{datetime_string(time2)}"
      end
    end
  end

  describe '#render_correct_answer_protection' do
    it 'should provide a useful message when "last attempt"' do
      quiz = stub({
        show_correct_answers_last_attempt: true,
      })

      message = render_correct_answer_protection(quiz)
      expect(message).to match /last attempt/
    end
    it 'should provide a useful message when "no"' do
      quiz = stub({
        show_correct_answers_last_attempt: nil,
        show_correct_answers: false,
        show_correct_answers_at: nil,
        hide_correct_answers_at: nil
      })

      message = render_correct_answer_protection(quiz)
      expect(message).to match /are hidden/
    end

    it 'should provide nothing when "yes"' do
      quiz = stub({
        show_correct_answers_last_attempt: nil,
        show_correct_answers: true,
        show_correct_answers_at: nil,
        hide_correct_answers_at: nil
      })

      message = render_correct_answer_protection(quiz)
      expect(message).to eq nil
    end

    it 'should provide a useful message, and an availability date, when "show at" is set' do
      quiz = stub({
        show_correct_answers_last_attempt: nil,
        show_correct_answers: true,
        show_correct_answers_at: 1.day.from_now,
        hide_correct_answers_at: nil
      })

      message = render_correct_answer_protection(quiz)
      expect(message).to match /will be available/
    end

    it 'should provide a useful message, and a date, when "hide at" is set' do
      quiz = stub({
        show_correct_answers_last_attempt: nil,
        show_correct_answers: true,
        show_correct_answers_at: nil,
        hide_correct_answers_at: 1.day.from_now
      })

      message = render_correct_answer_protection(quiz)
      expect(message).to match /are available until/
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
        expect(point_value_for_input(user_answer, question)).to eq user_answer[:points]
      end
    end

    it "returns -- if quiz is practice quiz or assignment" do
      ['assignment', 'practice_quiz'].each do |quiz_type|
        @quiz.expects(:quiz_type).returns quiz_type
        expect(point_value_for_input(user_answer, question)).to eq "--"
      end
    end

    it "returns points possible for the question if (un)graded survey" do
      ['survey', 'graded_survey'].each do |quiz_type|
        @quiz.expects(:quiz_type).returns quiz_type
        expect(point_value_for_input(user_answer, question)).to eq(
          question[:points_possible]
        )
      end
    end
  end
end
