#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'nokogiri'

describe "concluded/unconcluded courses" do
  before(:each) do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    @e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    @e.save!

    user_session(@user, @pseudonym)

    user_model
    @student = @user
    @course.enroll_student(@student).accept
    @group = @course.assignment_groups.create!(:name => "default")
    @assignment = @course.assignments.create!(:submission_types => 'online_quiz', :title => 'quiz assignment', :assignment_group => @group)
    @quiz = @assignment.reload.quiz
    @qsub = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
    @qsub.quiz_data = [{:correct_comments=>"", :assessment_question_id=>nil, :incorrect_comments=>"", :question_name=>"Question 1", :points_possible=>1, :question_text=>"Which book(s) are required for this course?", :name=>"Question 1", :id=>128, :answers=>[{:weight=>0, :text=>"A", :comments=>"", :id=>1490}, {:weight=>0, :text=>"B", :comments=>"", :id=>1020}, {:weight=>0, :text=>"C", :comments=>"", :id=>7051}], :question_type=>"multiple_choice_question"}]
    @qsub.submission_data = [{:points=>0, :text=>"7051", :question_id=>128, :correct=>false, :answer_id=>7051}]
    @qsub.workflow_state = 'complete'
    @qsub.save!
    @sub = @qsub.submission
  end

  it "should let the teacher change grades in the speed grader by default" do
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML(response.body)
    expect(html.css('#add_a_comment').length).to eq 1
    expect(html.css('#grade_container').length).to eq 1
  end

  it "should not let the teacher change grades in the speed grader when concluded" do
    @e.conclude

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML(response.body)
    expect(html.css('#add_a_comment').length).to eq 0
    expect(html.css('#grade_container').length).to eq 0
  end

  it "should let the teacher change grades on the submission details page by default" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML(response.body)
    expect(html.css('.submission_details .grading_box').length).to eq 1
    expect(html.css('#add_comment_form').length).to eq 1
  end

  it "should not let the teacher change grades on the submission details page when concluded" do
    @e.conclude

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML(response.body)
    expect(html.css('.submission_details .grading_box').length).to eq 0
    expect(html.css('#add_comment_form')[0]['style']).to match(/display: none/)
  end

  it "should let the teacher change quiz submission scores by default" do
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@qsub.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML(response.body)
    expect(html.css('#fudge_points_entry').length).to eq 1
    expect(html.css('.quiz_comment textarea').length).to eq 1
    expect(html.css('.user_points .question_input').length).to eq 1
  end

  it "should not let the teacher change quiz submission scores when concluded" do
    @e.conclude

    get "/courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@qsub.id}"
    expect(response).to be_successful

    html = Nokogiri::HTML(response.body)
    expect(html.css('#fudge_points_entry').length).to eq 0
    expect(html.css('.quiz_comment textarea').length).to eq 0
    expect(html.css('.user_points .question_input').length).to eq 0
  end

end


