# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

require 'csv'

describe Quizzes::QuizStatistics::StudentAnalysis do

  def temporary_user_code
    "tmp_#{Digest::MD5.hexdigest("#{Time.now.to_i}_#{rand}")}"
  end

  def survey_with_logged_out_submission
    course_with_teacher(:active_all => true)

    @assignment = @course.assignments.create(:title => "Test Assignment")
    @assignment.workflow_state = "available"
    @assignment.submission_types = "online_quiz"
    @assignment.save
    @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first
    @quiz.anonymous_submissions = false
    @quiz.quiz_type = "survey"

    # make questions
    questions = [{:question_data => { :name => "test 1" }},
      {:question_data => { :name => "test 2" }},
      {:question_data => { :name => "test 3" }},
      {:question_data => { :name => "test 4" }}]

    @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
    @quiz.generate_quiz_data
    @quiz.save!

    @quiz_submission = @quiz.generate_submission(temporary_user_code)
    @quiz_submission.mark_completed
    Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
    @quiz_submission.save!
  end

  let(:report_type) { 'student_analysis' }
  include_examples "Quizzes::QuizStatistics::Report"
  before(:once) { course_factory }

  def csv(opts = {}, quiz = @quiz)
    opts[:includes_sis_ids] = true unless opts.key?(:includes_sis_ids)
    stats = quiz.statistics_csv('student_analysis', opts)
    run_jobs
    stats.reload_csv_attachment.open.read
  end

  it 'should calculate mean/stddev as expected with no submissions' do
    q = @course.quizzes.create!
    stats = q.statistics
    expect(stats[:submission_score_average]).to be_nil
    expect(stats[:submission_score_high]).to be_nil
    expect(stats[:submission_score_low]).to be_nil
    expect(stats[:submission_score_stdev]).to be_nil
  end

  it 'should calculate mean/stddev as expected with a few submissions' do
    q = @course.quizzes.create!
    question = q.quiz_questions.create!({
      question_data: {
        name: 'q1',
        points_possible: 30,
        question_type: 'essay_question',
        question_text: 'ohai mark'
      }
    })
    q.generate_quiz_data
    q.save!

    @user1 = User.create! :name => "some_user 1"
    @user2 = User.create! :name => "some_user 2"
    @user3 = User.create! :name => "some_user 2"
    student_in_course :course => @course, :user => @user1
    student_in_course :course => @course, :user => @user2
    student_in_course :course => @course, :user => @user3
    sub = q.generate_submission(@user1)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 10, :text => "", :correct => "undefined", :question_id => question.id }]
    # simulate a positive fudge of 5 points:
    sub.score = 15
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    expect(stats[:submission_score_average]).to eq 15
    expect(stats[:submission_score_high]).to eq 15
    expect(stats[:submission_score_low]).to eq 15
    expect(stats[:submission_score_stdev]).to eq 0
    expect(stats[:submission_scores]).to eq({ 50 => 1 })
    sub = q.generate_submission(@user2)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 17, :text => "", :correct => "undefined", :question_id => question.id }]
    sub.score = 17
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    expect(stats[:submission_score_average]).to eq 16
    expect(stats[:submission_score_high]).to eq 17
    expect(stats[:submission_score_low]).to eq 15
    expect(stats[:submission_score_stdev]).to eq 1
    expect(stats[:submission_scores]).to eq({ 50 => 1, 57 => 1 })
    sub = q.generate_submission(@user3)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 20, :text => "", :correct => "undefined", :question_id => question.id }]
    sub.score = 20
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    expect(stats[:submission_score_average]).to be_within(0.0000000001).of(17 + 1.0/3)
    expect(stats[:submission_score_high]).to eq 20
    expect(stats[:submission_score_low]).to eq 15
    expect(stats[:submission_score_stdev]).to be_within(0.0000000001).of(Math::sqrt(4 + 2.0/9))
    expect(stats[:submission_scores]).to eq({ 50 => 1, 57 => 1, 67 => 1 })
  end

  it 'should create quiz statistics with essay questions and anonymous submissions' do
    @user1 = User.create! :name => "some_user 1"
    student_in_course :course => @course, :user => @user1
    quiz = @course.quizzes.create!
    quiz.update(:published_at => Time.zone.now, :quiz_type => 'survey', :anonymous_submissions => true)
    quiz.quiz_questions.create!(question_data: essay_question_data)
    quiz.generate_quiz_data
    quiz.save
    qs = quiz.generate_submission(@user1)
    qs.submission_data = { "question_#{quiz.quiz_data[0][:id]}" => "Essay response user 1" }
    qs.workflow_state = 'complete'
    qs.save
    expect do
      quiz.quiz_statistics.build(:report_type => 'student_analysis',
                                 :includes_all_versions => true,
                                 :anonymous => true).report.generate(false)
    end.to_not raise_error
  end

  it 'should create quiz statistics with logged out users' do
    survey_with_logged_out_submission
    expect do
      @quiz.quiz_statistics.build(report_type: 'student_analysis',
                                  includes_all_versions: true,
                                  anonymous: false).report.generate(false)
    end.to_not raise_error
  end

  context "csv" do
    before(:each) do
      student_in_course(:active_all => true)
      @quiz = @course.quizzes.create!
      @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.save!
    end

    it 'should not include user data for anonymous surveys' do
      @quiz.update_attribute :anonymous_submissions, true
      # one complete submission
      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission

      # and one in progress
      @quiz.generate_submission(@student)
      stats = CSV.parse(csv(:include_all_versions => true))
      expect(stats.last.length).to eq 9
      stats.first.first == "section"
    end

    it 'should include sis ids when requested' do
      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission

      stats = CSV.parse(csv(includes_sis_ids: true))
      expect(stats.last.length).to eq 12
      expect(stats.first).to include 'sis_id'
      expect(stats.first).to include 'section_sis_id'
    end

    it 'should not include sis ids when not requested' do
      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission

      stats = CSV.parse(csv(includes_sis_ids: false))
      expect(stats.last.length).to eq 10
      expect(stats.first).not_to include 'sis_id'
      expect(stats.first).not_to include 'section_sis_id'
    end

    it 'should succeed with logged-out user submissions' do
      survey_with_logged_out_submission
      stats = CSV.parse(csv(:include_all_versions => true))
      expect(stats.last[0]).to eq ''
      expect(stats.last[1]).to eq ''
      expect(stats.last[2]).to eq ''
    end

    it 'should have sections in quiz statistics_csv' do
      # enroll user in multiple sections
      pseudonym(@student)
      @student.pseudonym.sis_user_id = "user_sis_id_01"
      @student.pseudonym.save!
      section1 = @course.course_sections.first
      section1.sis_source_id = 'SISSection01'
      section1.save!
      section2 = CourseSection.new(:course => @course, :name => "section2")
      section2.sis_source_id = 'SISSection02'
      section2.save!
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active', :allow_multiple_enrollments => true, :section => section2)
      @student.save!
      # one complete submission
      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission
      stats = CSV.parse(csv(:include_all_versions => true))
      expect(stats.last[0]).to eq "nobody@example.com"
      expect(stats.last[1]).to eq @student.id.to_s
      expect(stats.last[2]).to eq "user_sis_id_01"

      splitter = lambda { |str| str.split(",").map(&:strip) }
      sections = splitter.call(stats.last[3])
      expect(sections).to include("section2")
      expect(sections).to include("Unnamed Course")

      section_ids = splitter.call(stats.last[4])
      expect(section_ids).to include(section2.id.to_s)
      expect(section_ids).to include(section1.id.to_s)

      section_sis_ids = splitter.call(stats.last[5])
      expect(section_sis_ids).to include("SISSection02")
      expect(section_sis_ids).to include("SISSection01")
    end

    it 'should use sections in quiz statistics generate' do
      # enroll user in multiple sections
      pseudonym(@student)
      @student.pseudonym.sis_user_id = "user_sis_id_01"
      @student.pseudonym.save!
      section1 = @course.course_sections.first
      section1.sis_source_id = 'SISSection01'
      section1.save!
      section2 = CourseSection.new(:course => @course, :name => "section2")
      section2.sis_source_id = 'SISSection02'
      section2.save!
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active',
                          :allow_multiple_enrollments => true, :section => section2)
      @student.save!

      question = @quiz.quiz_questions.create!({
                                              question_data: {
                                                name: 'q1',
                                                points_possible: 30,
                                                question_type: 'essay_question',
                                                question_text: 'ohai mark'
                                              }
                                             })
      @quiz.generate_quiz_data
      @quiz.save!

      # one complete submission
      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission
      stats = @quiz.quiz_statistics.build(
        :report_type => 'student_analysis',
        :includes_all_versions => true
        ).report.generate(true, {:section_ids=> section2.id})
      expect(stats[:questions][0][1]["answers"][0]["responses"]).to eq 1
    end

    it 'should deal with incomplete fill-in-multiple-blanks questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "test 2",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0]",
        :answers =>
          [{'answer_text' => 'foo', 'blank_id' => 'ans0', 'answer_weight' => '100'}]})
      @quiz.quiz_questions.create!(:question_data => { :name => "test 3",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0] [ans1]",
        :answers =>
           [{'answer_text' => 'bar', 'blank_id' => 'ans0', 'answer_weight' => '100'},
            {'answer_text' => 'baz', 'blank_id' => 'ans1', 'answer_weight' => '100'}]})
      @quiz.generate_quiz_data
      @quiz.save!
      expect(@quiz.quiz_questions.size).to eq 3
      qs = @quiz.generate_submission(@student)
      # submission will not answer question 2 and will partially answer question 3
      qs.submission_data = {
          "question_#{@quiz.quiz_questions[2].id}_#{AssessmentQuestion.variable_id('ans1')}" => 'baz'
      }
      Quizzes::SubmissionGrader.new(qs).grade_submission
      stats = CSV.parse(csv)
      expect(stats.last.size).to eq 16 # 3 questions * 2 lines + ten more (name, id, sis_id, section, section_id, section_sis_id, submitted, correct, incorrect, score)
      expect(stats.last[11]).to eq ',baz'
    end

    it 'should contain answers to numerical questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "numerical_question",
        :question_type => 'numerical_question',
        :question_text => "[num1]",
        :answers => {'answer_0' => {:numerical_answer_type => 'exact_answer'}}})

      @quiz.quiz_questions.last.question_data[:answers].first[:exact] = 5

      @quiz.generate_quiz_data
      @quiz.save!

      qs = @quiz.generate_submission(@student)
      qs.submission_data = {
        "question_#{@quiz.quiz_questions[1].id}" => 5
      }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      stats = CSV.parse(csv)
      expect(stats.last[9]).to eq '5'
    end

    it 'should not error out when no answers are present in a calculated_question' do
      @quiz.quiz_questions.create!(:question_data => { :name => "calculated_question",
        :question_type => 'calculated_question',
        :question_text => "[num1]"
      })

      @quiz.generate_quiz_data
      @quiz.save!

      qs = @quiz.generate_submission(@student)
      qs.submission_data = {
        "question_#{@quiz.quiz_questions[1].id}" => 'Pretend this is an essay question!'
      }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      expect { @quiz.statistics_csv('student_analysis', {}) }.not_to raise_error
    end

    it 'should not error out when answers is null in a text_only_question' do
      @quiz.quiz_questions.create!(:question_data => { :name => "text_only_question",
        :question_type => 'text_only_question',
        :question_text => "[num1]",
        :answers => nil
      })

      @quiz.generate_quiz_data
      @quiz.save!

      qs = @quiz.generate_submission(@student)
      qs.submission_data = {
        "question_#{@quiz.quiz_questions[1].id}" => 'Pretend this is an essay question!'
      }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      expect { @quiz.statistics_csv('student_analysis', {}) }.not_to raise_error
    end

    it 'should include primary domain if trust exists' do
      account2 = Account.create!
      allow(HostUrl).to receive(:context_host).and_return('school')
      expect(HostUrl).to receive(:context_host).with(account2).and_return('school1')
      @student.pseudonyms.scope.delete_all
      account2.pseudonyms.create!(user: @student, unique_id: 'user') { |p| p.sis_user_id = 'sisid' }
      allow_any_instantiation_of(@quiz.context.root_account).to receive(:trust_exists?).and_return(true)
      allow_any_instantiation_of(@quiz.context.root_account).to receive(:trusted_account_ids).and_return([account2.id])

      qs = @quiz.generate_submission(@student)
      Quizzes::SubmissionGrader.new(qs).grade_submission
      stats = CSV.parse(csv(:include_all_versions => true))
      expect(stats[1][3]).to eq 'school1'
    end
  end

  it "includes attachment display names for quiz file upload questions" do
    student_in_course(:active_all => true)
    student = @student
    student.name = "Not Steve"
    student.save!
    student2 = User.create!(:name => "Stevie Jeebie")
    @course.enroll_user(student2,'StudentEnrollment', :enrollment_state => :active)
    q = @course.quizzes.create!(:title => "new quiz")
    q.update_attribute :published_at, Time.now
    question = q.quiz_questions.create! :question_data => {
      :name => 'q1', :points_possible => 1,
      :question_type => 'file_upload_question',
      :question_text => 'ohai mark'
    }
    q.generate_quiz_data
    q.save!
    qs = q.generate_submission student
    io = fixture_file_upload('docs/doc.doc', 'application/msword', true)
    attach = qs.attachments.create! :filename => "doc.doc",
      :display_name => "attachment.png", :user => student,
      :uploaded_data => io
    qs.submission_data["question_#{question.id}".to_sym] = [ attach.id.to_s ]
    qs.save!
    Quizzes::SubmissionGrader.new(qs).grade_submission
    qs = q.generate_submission student2
    qs.submission_data["question_#{question.id}".to_sym] = nil
    qs.save!
    Quizzes::SubmissionGrader.new(qs).grade_submission
    # make student2's submission first
    qs.updated_at = 3.days.ago
    qs.save!
    stats = CSV.parse(csv({:include_all_versions => true},q.reload))
    stats = stats.sort_by {|s| s[1] } # sort by the id
    expect(stats.first[7]).to eq attach.display_name
  end

  it 'should strip tags from html multiple-choice/multiple-answers' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!(:title => "new quiz")
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => [{'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, {'answer_text' => 'lolrus', 'answer_weight' => '100'}]})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # visual statistics
    stats = q.statistics
    expect(stats[:questions].length).to eq 2
    expect(stats[:questions][0].length).to eq 2
    expect(stats[:questions][0][0]).to eq "question"
    expect(stats[:questions][0][1][:answers].length).to eq 2
    expect(stats[:questions][0][1][:answers][0][:responses]).to eq 1
    expect(stats[:questions][0][1][:answers][0][:text]).to eq "zero"
    expect(stats[:questions][0][1][:answers][1][:responses]).to eq 0
    expect(stats[:questions][0][1][:answers][1][:text]).to eq "one"
    expect(stats[:questions][1].length).to eq 2
    expect(stats[:questions][1][0]).to eq "question"
    expect(stats[:questions][1][1][:answers].length).to eq 2
    expect(stats[:questions][1][1][:answers][0][:responses]).to eq 1
    expect(stats[:questions][1][1][:answers][0][:text]).to eq "lolcats"
    expect(stats[:questions][1][1][:answers][1][:responses]).to eq 1
    expect(stats[:questions][1][1][:answers][1][:text]).to eq "lolrus"

    # csv statistics
    stats = CSV.parse(csv({}, q))
    expect(stats.last[7]).to eq "zero"
    expect(stats.last[9]).to eq "lolcats,lolrus"
  end

  it 'should not strip things that look like tags from essay questions' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!
    q.update_attribute(:published_at, Time.zone.now)
    q.quiz_questions.create!(question_data: essay_question_data)
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
      "question_#{q.quiz_data[0][:id]}" => "<p class=\"p1\"><span class=\"s1\">&lt;&gt; &lt; &gt; WHERE rental_duration &gt;= 6 AND rating &lt;&gt; 'R' 1 &lt; 3 &gt; 2</span></p>"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = CSV.parse(csv({}, q))
    expect(stats.last[7]).to eq "<> < > WHERE rental_duration >= 6 AND rating <> 'R' 1 < 3 > 2"
  end

  it 'should strip tags from all student-provided answers' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(question_data: short_answer_question_data)
    q.quiz_questions.create!(question_data: fill_in_multiple_blanks_question_one_blank_data)
    q.quiz_questions.create!(question_data: essay_question_data)
    q.quiz_questions.create!(question_data: numerical_question_data)
    q.quiz_questions.create!(question_data: calculated_question_data)
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
      "question_#{q.quiz_data[0][:id]}" => "<em>short_answer</em>",
      "question_#{q.quiz_data[1][:id]}_#{AssessmentQuestion.variable_id("myblank")}" => "<em>fimb</em>",
      "question_#{q.quiz_data[2][:id]}" => "<em>essay</em>",
      "question_#{q.quiz_data[3][:id]}" => "<em>numerical</em>",
      "question_#{q.quiz_data[4][:id]}" => "<em>calculated</em>",
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = CSV.parse(csv({}, q))
    expect(stats.last[7]).to eq "short_answer"
    expect(stats.last[9]).to eq "fimb"
    expect(stats.last[11]).to eq "essay"
    expect(stats.last[13]).to eq "numerical"

    # calculated field also includes the values for the variables, something like:
    #   "x=>4.3,y=>21,calculated"
    # so we'll match instead
    expect(stats.last[15]).to match /,calculated$/
  end

  it 'should not count teacher preview submissions' do
    teacher_in_course(:active_all => true)
    q = @course.quizzes.create!
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => [{'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, {'answer_text' => 'lolrus', 'answer_weight' => '100'}]})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@teacher, true)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = q.statistics
    expect(stats[:unique_submission_count]).to eq 0
  end

  it 'should not show student names for anonymous submissions' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!
    q.update(:published_at => Time.zone.now, :quiz_type => 'survey', :anonymous_submissions => true)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = q.statistics

    expect(stats[:questions].first.last[:user_ids].first).to eq nil
  end

  it 'should not count student view submissions' do
    @course = course_factory(active_all: true)
    fake_student = @course.student_view_student
    q = @course.quizzes.create!
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}]})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => [{'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, {'answer_text' => 'lolrus', 'answer_weight' => '100'}]})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(fake_student)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = q.statistics
    expect(stats[:unique_submission_count]).to eq 0
  end

  describe 'question statistics' do
    subject { Quizzes::QuizStatistics::StudentAnalysis.new({}) }

    it 'should proxy to CanvasQuizStatistics for supported questions' do
      question_data = { question_type: 'essay_question' }
      responses = []

      expect(CanvasQuizStatistics).to receive(:analyze).
          with(question_data, responses).
          and_return({ some_metric: 5 })

      output = subject.send(:stats_for_question, question_data, responses, false)
      expect(output).to eq({
        question_type: 'essay_question',
        some_metric: 5
      })
    end

    it "shouldn't proxy if the legacy flag is on" do
      question_data = {
        question_type: 'essay_question',
        answers: []
      }

      expect(CanvasQuizStatistics).to receive(:analyze).never

      subject.send(:stats_for_question, question_data, [])
    end
  end
end
