#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/gradezilla_page'

describe 'Gradebook frontend/backend calculators' do
  include_context 'in-process server selenium tests'

  before :once do
    skip("Unskip in GRADE-1871")
    @unlucky1 = [95.86, 66.62, 76.98, 87.85, 68.32, 94.32, 62.6, 81.59, 92.21, 90.31, 82.26, 70.88, 83.24, 90.83, 65.74, 73.05, 94.16, 65.3, 78.92, 87.11]
    @unlucky2 = [93.33, 88.32, 61.29, 83.57, 86.61, 77.36, 84.72, 63.51, 78.43, 82.44, 85.3, 65.51, 81.29, 76.52, 90.13, 71.1, 61.56, 90.05, 67.07, 96.76]
    @unlucky3 = [95.36, 90.12, 62.08, 91.67, 87.34, 77.01, 75.63, 64.18, 81.69, 65.87, 73.38, 91.17, 85.68, 72.33, 70.4, 74.86, 63.74, 96.16, 62.09, 97.29]
    @unlucky4 = [80.04, 71.57, 84.63, 65.52, 79.57, 92.11, 94.96, 86.55, 68.65, 64.64, 67.63, 67.56, 68.77, 85.49, 67.33, 83.11, 93.51, 63.59, 89.27, 65.11]
    @unlucky5 = [76.37, 93.29, 71.61, 93.27, 78.84, 84.8, 85.73, 89.58, 80.94, 82.55, 62.53, 73.87, 89.76, 95.58, 85.15, 71.77, 98.82, 71.51, 70.91, 71.93]
    @unlucky6 = [99.57, 60.26, 90.51, 91.05, 93.59, 89.08, 84.77, 81.6, 87.75, 78.05, 94.31, 60.0, 96.03, 80.32, 92.43, 66.69, 79.98, 88.08, 98.58, 64.22]
    @unlucky7 = [97.09, 68.1, 78.51, 98.56, 82.56, 86.73, 94.86, 86.21, 81.35, 71.99, 70.18, 79.17, 71.32, 94.49, 69.88, 91.9, 96.17, 86.17, 90.3, 85.35]
    @unlucky8 = [65.11, 89.27, 63.59, 93.51, 83.11, 67.33, 85.49, 68.77, 67.56, 67.63, 64.64, 68.65, 86.55, 94.96, 92.11, 79.57, 65.52, 84.63, 71.57, 80.04]

    @unlucky_group = [@unlucky1,@unlucky2,@unlucky3,@unlucky4,@unlucky5,@unlucky6,@unlucky7,@unlucky8]
    grades_sample = (60.0..100.0).step(0.01).map { |x| x.round(2) }

    @teacher = user_factory(active_all: true)
    @courses = create_courses(8, enroll_user: @user, return_type: :record)
    student_data = create_users(2, return_type: :record, name_prefix: "Jack")
    @courses.each_with_index do |course, course_index|
      grades = @unlucky_group[course_index]

      course.enable_feature!(:new_gradebook)
      create_enrollments(course, student_data)
      group = course.assignment_groups.create! name: 'assignments'
      assignments = create_assignments(
        [course.id],
        20,
        points_possible: 10.0,
        submission_types: "online_text_entry,online_upload",
        assignment_group_id: group.id
      )
      # submissions of grades known to cause floating precision error
      create_records(
        Submission,
        assignments.each_with_index.map do |id, index|
          {
            assignment_id: id,
            user_id: student_data.first.id,
            body: "hello",
            workflow_state: "graded",
            submission_type: 'online_text_entry',
            grader_id: @teacher.id,
            grade: grades[index].to_s,
            score: grades[index],
            graded_at: Time.zone.now,
            grade_matches_current_submission: true
          }
        end
      )
      # random grades to help identify any potential floating precision errors
      create_records(
        Submission,
        assignments.map do |id|
          random = grades_sample.sample
          {
            assignment_id: id,
            user_id: student_data.second.id,
            body: "hello",
            workflow_state: "graded",
            submission_type: 'online_text_entry',
            grader_id: @teacher.id,
            grade: random.to_s,
            score: random,
            graded_at: Time.zone.now,
            grade_matches_current_submission: true
          }
        end
      )

      DueDateCacher.recompute_course(course, update_grades: true)
    end
  end

  8.times do |i|
    it "final grades match with unlucky#{i} and course#{i}" do
      # need to expand and bring all rows into view in order to scrape
      driver.manage.window.resize_to(2000,900)
      user_session(@teacher)
      Gradezilla.visit(@courses[i])
      @frontend_grades = Gradezilla.scores_scraped
      @backend_grades = Gradezilla.scores_api(@courses[i])
      @diff = @frontend_grades - @backend_grades

      @diff.each do |entry|
        puts "USER: #{entry[:user_id]} scores: #{@unlucky_group[i].map{|v| {score: v }}}"
        puts "frontend grade: #{@frontend_grades.select{ |user| user[:user_id] == entry[:user_id]}}"
        puts "backend grade: #{@backend_grades.select{ |user| user[:user_id] == entry[:user_id]}}"
      end
      expect(@diff).to be_empty
    end
  end
end
