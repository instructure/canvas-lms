#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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
# How to run:
#
# In localhost environment, run:
#   script/rails runner spec/fixtures/data_generation/generate_data.rb [options]
#
# In docker environment, run:
#   docker-compose run web bundle exec rails runner spec/fixtures/data_generation/generate_data.rb [options]

require_relative "../../factories/course_factory"
require_relative "../../factories/user_factory"
require_relative "../../factories/quiz_factory"
require_relative "../../factories/outcome_factory"

require "optparse"

# rubocop:disable Specs/ScopeIncludes
# rubocop:disable Style/MixinUsage
include Factories
# rubocop:enable Style/MixinUsage
# rubocop:enable Specs/ScopeIncludes

# rubocop:disable Specs/ScopeHelperModules
def toggle_k5_setting(account, enable = true)
  account.settings[:enable_as_k5_account] = { value: enable, locked: enable }
  account.root_account.settings[:k5_accounts] = enable ? [account.id] : []
  account.root_account.save!
  account.save!
end

def teacher_in_course(user, course_name)
  course_with_teacher(
    account: @root_account,
    active_course: 1,
    active_enrollment: 1,
    course_name:,
    course_code: SecureRandom.alphanumeric(10),
    user:
  )
end

def student_in_course(user, course)
  course_with_student(
    active_all: 1,
    course:,
    user:
  )
end

def course_with_enrollments
  course_with_teacher_enrolled
  course_with_students_enrolled
end

def course_with_teacher_enrolled
  course_with_teacher(
    account: @root_account,
    active_course: 1,
    active_enrollment: 1,
    course_name: @course_name,
    course_code: SecureRandom.alphanumeric(10),
    name: "Teacher Extraordinaire"
  )
  @teacher = @user
  @teacher.pseudonyms.create!(
    unique_id: "newteacher#{@teacher.id}@example.com",
    password: "password",
    password_confirmation: "password"
  )
  @teacher.email = "newteacher#{@teacher.id}@example.com"
  @teacher.accept_terms
  @teacher.register!
end

def course_with_students_enrolled
  @student_list = []
  @enrollment_list = []
  @number_of_students.times do
    index = SecureRandom.alphanumeric(10)
    course_with_student(
      account: @root_account,
      active_all: 1,
      course: @course,
      name: "PlayStudent #{index}"
    )
    @enrollment_list << @enrollment
    email = "playstudent#{index}@example.com"
    @user.pseudonyms.create!(
      unique_id: email,
      password: "password",
      password_confirmation: "password"
    )
    @user.email = email
    @user.accept_terms
    @student_list << @user
  end
  @student_list
end

def create_assignment(course, title, points_possible = 10)
  course.assignments.create!(
    title: "#{title} #{SecureRandom.alphanumeric(10)}",
    description: "General Assignment",
    points_possible:,
    submission_types: "online_text_entry",
    workflow_state: "published"
  )
end

def create_discussion(course, creator, workflow_state = "published")
  discussion_assignment = create_assignment(@course, "Discussion Assignment", 10)
  course.discussion_topics.create!(
    user: creator,
    title: "Discussion Topic #{SecureRandom.alphanumeric(10)}",
    message: "Discussion topic message",
    assignment: discussion_assignment,
    workflow_state:
  )
end

def create_quiz(course)
  due_at = 1.day.from_now(Time.zone.now)
  unlock_at = Time.zone.now.advance(days: -2)
  lock_at = Time.zone.now.advance(days: 4)
  title = "Test Quiz #{SecureRandom.alphanumeric(10)}"
  @context = course
  @quiz = quiz_model
  @quiz.generate_quiz_data
  @quiz.due_at = due_at
  @quiz.lock_at = lock_at
  @quiz.unlock_at = unlock_at
  @quiz.title = title
  @quiz.save!
  @quiz.quiz_questions.create!(
    question_data: {
      name: "Quiz Questions",
      question_type: "fill_in_multiple_blanks_question",
      question_text: "[color1]",
      answers: [{ text: "one", id: 1 }, { text: "two", id: 2 }, { text: "three", id: 3 }],
      points_possible: 1
    }
  )
  @quiz.generate_quiz_data
  @quiz.workflow_state = "available"
  @quiz.save
  @quiz.reload
  @quiz
end

def create_announcement(course, announcement_title, announcement_message)
  course.announcements.create!(
    title: announcement_title,
    message: announcement_message
  )
end

def create_wiki_page(course)
  course.wiki_pages.create!(title: "New Wiki Page #{SecureRandom.alphanumeric(10)}", body: "Here's where we have content")
end

def create_module(course, workflow_state = "active")
  course.context_modules.create!(name: "Module #{SecureRandom.alphanumeric(10)}", workflow_state:)
end

def create_outcome(course, outcome_description, outcome__short_description = "Another Outcome")
  outcome = course.created_learning_outcomes.create!(
    description: outcome_description,
    short_description: outcome__short_description
  )
  course.root_outcome_group.add_outcome(outcome)
  course.root_outcome_group.save!
  course.reload
  outcome
end

def print_student_info
  puts "Student IDs are:"
  @student_list.map do |n|
    puts "  #{n.name}: #{n.id}"
  end
end

def print_standard_course_info
  puts "Course ID is #{@course.id}"
  puts "Teacher ID is #{@teacher.id}"
  print_student_info
end

def generate_course_with_students
  puts "Generate Course with Students"
  course_with_enrollments

  print_standard_course_info
end

def generate_fully_loaded_course(number_of_items = 2)
  puts "Generate Loaded Course"
  course_with_enrollments
  number_of_items.times do
    create_assignment(@course, "Assignment")
    create_discussion(@course, @teacher)
    create_quiz(@course)
    create_announcement(@course, "new announcement", "new message")
    create_wiki_page(@course)
    course_module1 = create_module(@course)
    assignment = create_assignment(@course, "Module Assignment")
    course_module1.add_item(id: assignment.id, type: "assignment")
  end

  print_standard_course_info
end

def generate_k5_dashboard
  puts "Generate K5 Dashboard Homeroom and Subjects"
  toggle_k5_setting(@root_account, true)
  course_with_teacher_enrolled
  homeroom = @course
  homeroom.homeroom_course = true
  homeroom.save!
  student_list = course_with_students_enrolled
  # add subjects
  ["Math", "Reading", "Social Studies", "Art", "Science"].each do |subject|
    teacher_in_course(@teacher, subject)
    create_announcement(@course, "#{subject} is awesome", "#{subject} will do you good")
    student_list.each do |student|
      student_in_course(student, @course)
    end
  end

  puts "Homeroom Course ID is #{homeroom.id}"
  puts "Teacher ID is #{@teacher.id}"
  print_student_info
end

def generate_bp_course_and_associations
  puts "Generate Blueprint Course and Associated Course"
  course_with_teacher_enrolled
  @blueprint_course = @course
  @main_teacher = @teacher
  @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
  @minion = @template.add_child_course!(course_factory(account: @root_account, course_name: "Minion", active_all: true)).child_course
  @minion.enroll_teacher(@main_teacher).accept!

  puts "Blueprint Course ID is #{@blueprint_course.id}"
  puts "Associated Course ID is #{@minion.id}"
  puts "Teacher ID is #{@teacher.id}"
end

def generate_course_and_submissions
  puts "Generate Course with Student Submissions"
  student_list = course_with_enrollments
  assignment = create_assignment(@course, "Assignment to submit")
  student_list.each do |student|
    assignment.submit_homework(student, { submission_type: "online_text_entry", body: "Here it is" })
    assignment.grade_student(student, grader: @teacher, score: 75, points_deducted: 0)
  end

  print_standard_course_info
  puts "Assignment ID is #{assignment.id}"
end

def generate_mastery_path_course
  puts "Generate Course with Mastery Path"
  course_with_enrollments
  @course.conditional_release = true
  @course.save!

  @trigger_assignment = create_assignment(@course, "Mastery Path Main Assignment", 10)
  @set1_assmt1 = create_assignment(@course, "Set 1 Assessment 1", 10)
  @set2_assmt1 = create_assignment(@course, "Set 2 Assessment 1", 10)
  @set2_assmt2 = create_assignment(@course, "Set 2 Assessment 2", 10)
  @set3a_assmt = create_assignment(@course, "Set 3a Assessment", 10)
  @set3b_assmt = create_assignment(@course, "Set 3b Assessment", 10)

  graded_discussion = create_discussion(@course, @teacher)

  course_module = @course.context_modules.create!(name: "Mastery Path Module")
  course_module.add_item(id: @trigger_assignment.id, type: "assignment")
  course_module.add_item(id: @set1_assmt1.id, type: "assignment")
  course_module.add_item(id: graded_discussion.id, type: "discussion_topic")
  course_module.add_item(id: @set2_assmt1.id, type: "assignment")
  course_module.add_item(id: @set2_assmt2.id, type: "assignment")
  course_module.add_item(id: @set3a_assmt.id, type: "assignment")
  course_module.add_item(id: @set3b_assmt.id, type: "assignment")

  ranges = [
    ConditionalRelease::ScoringRange.new(lower_bound: 0.7, upper_bound: 1.0, assignment_sets: [
                                           ConditionalRelease::AssignmentSet.new(assignment_set_associations: [
                                                                                   ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set1_assmt1.id),
                                                                                   ConditionalRelease::AssignmentSetAssociation.new(assignment_id: graded_discussion.assignment_id)
                                                                                 ])
                                         ]),
    ConditionalRelease::ScoringRange.new(lower_bound: 0.4, upper_bound: 0.7, assignment_sets: [
                                           ConditionalRelease::AssignmentSet.new(assignment_set_associations: [
                                                                                   ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set2_assmt1.id),
                                                                                   ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set2_assmt2.id)
                                                                                 ])
                                         ]),
    ConditionalRelease::ScoringRange.new(lower_bound: 0, upper_bound: 0.4, assignment_sets: [
                                           ConditionalRelease::AssignmentSet.new(
                                             assignment_set_associations: [ConditionalRelease::AssignmentSetAssociation.new(
                                               assignment_id: @set3a_assmt.id
                                             )]
                                           ),
                                           ConditionalRelease::AssignmentSet.new(
                                             assignment_set_associations: [ConditionalRelease::AssignmentSetAssociation.new(
                                               assignment_id: @set3b_assmt.id
                                             )]
                                           )
                                         ])
  ]
  @rule = @course.conditional_release_rules.create!(trigger_assignment: @trigger_assignment, scoring_ranges: ranges)

  print_standard_course_info
  puts "Trigger Assignment ID is #{@trigger_assignment.id}"
end

def generate_sections(number_of_sections = 2)
  puts "Generate Course with Students in Sections"
  course_with_teacher_enrolled
  number_of_sections.times do |iteration|
    section = @course.course_sections.create!(name: "Section #{iteration + 1}")
    course_with_students_enrolled
    @enrollment_list.each do |student_enrollment|
      student_enrollment.course_section = section
      student_enrollment.save!
    end
  end

  puts "Course ID is #{@course.id}"
end

def generate_course_with_outcome_rubric
  puts "Generate course with assignment associated with outcome rubric"
  course_with_teacher_enrolled
  course_with_students_enrolled
  rubric = outcome_with_rubric(course: @course)
  assignment = create_assignment(@course, "Rubric Assignment")
  rubric.associate_with(assignment, @course, purpose: "grading", use_for_grading: true)

  print_standard_course_info
  puts "Assignment ID is #{assignment.id}"
  puts "Rubric ID is #{rubric.id}"
end

def generate_course_assignment_groups
  puts "Generate course with assignment groups"
  course_with_teacher_enrolled
  course_with_students_enrolled

  @course.require_assignment_group
  assignment_group1 = @course.assignment_groups.create!(name: "AG 1")
  assignment_group2 = @course.assignment_groups.create!(name: "AG 2")
  assignment1 = create_assignment(@course, "Assignment 1")
  assignment2 = create_assignment(@course, "Assignment 2")
  assignment1.assignment_group = assignment_group1
  assignment1.save!
  assignment2.assignment_group = assignment_group2
  assignment2.save!

  print_standard_course_info
  puts "Assignment 1 ID is #{assignment1.id}"
  puts "Assignment 2 ID is #{assignment2.id}"
  puts "Assignment Group 1 ID is #{assignment_group1.id}"
  puts "Assignment Group 2 ID is #{assignment_group2.id}"
end

def generate_course_with_dated_assignments
  puts "Generate course with 10 dates assignments for syllabus"
  course_with_teacher_enrolled
  10.times do |iteration|
    assignment = create_assignment(@course, "Assignment #{iteration + 1}")
    assignment.due_at = (iteration + 1).day.from_now(Time.zone.now)
    assignment.save!
  end

  puts "Course ID is #{@course.id}"
  puts "Teacher ID is #{@teacher.id}"
end

def generate_course_pace_course
  puts "Generate a course pace course with module and assignments"
  course_with_teacher_enrolled
  course_with_students_enrolled

  @root_account.enable_feature!(:course_paces)
  @course.update(enable_course_paces: true)

  module1 = create_module(@course)
  assignment1 = create_assignment(@course, "Assignment 1")
  assignment2 = create_assignment(@course, "Assignment 2")
  discussion1 = create_discussion(@course, @teacher)
  quiz1 = create_quiz(@course)
  module1.add_item(id: assignment1.id, type: "assignment")
  module1.add_item(id: assignment2.id, type: "assignment")
  module1.add_item(id: discussion1.id, type: "discussion_topic")
  module1.add_item(id: quiz1.id, type: "quiz")

  print_standard_course_info
  puts "Assignment 1 ID is #{assignment1.id}"
  puts "Assignment 2 ID is #{assignment2.id}"
  puts "Discussion ID is #{discussion1.id}"
  puts "Module ID is #{module1.id}"
end

def create_all_the_available_data
  save_course_name = @course_name
  @course_name = save_course_name + " (course with students)"
  generate_course_with_students
  @course_name = save_course_name + " (fully loaded)"
  generate_fully_loaded_course
  @course_name = save_course_name + " (K5 Dashboard)"
  generate_k5_dashboard
  @course_name = save_course_name + " (blueprint course)"
  generate_bp_course_and_associations
  @course_name = save_course_name + " (course with submissions)"
  generate_course_and_submissions
  @course_name = save_course_name + " (mastery path course)"
  generate_mastery_path_course
  @course_name = save_course_name + " (course with sections)"
  generate_sections
  @course_name = save_course_name + " (course with dated assignments)"
  generate_course_with_dated_assignments
  @course_name = save_course_name + " (course with outcome and rubric)"
  generate_course_with_outcome_rubric
  @course_name = save_course_name + " (course with assignment groups)"
  generate_course_assignment_groups
  @course_name = save_course_name + " (course pace course)"
  generate_course_pace_course
end
# rubocop:enable Specs/ScopeHelperModules

options = {}
ARGV << "-h" if ARGV.empty?
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: bin/rails runner spec/fixtures/data_generation/generate_data.rb [-abdgklmprsth] [-c course_name] [-n number_of_students]"
  opts.on("-a", "--all_data", "Create all the available data with defaults")
  opts.on("-b", "--basic_course", "Course with teacher and students")
  opts.on("-c", "--course_name=COURSENAME", "Course Name")
  opts.on("-e", "--course_pace", "Course Pacing Course")
  opts.on("-d", "--dated_assignments", "Course with Dated Assignments")
  opts.on("-g", "--assignment_groups", "Course with Assignments in assignment groups")
  opts.on("-i", "--account_id=ACCOUNTID", "Id Number of the root account")
  opts.on("-k", "--k5_dash", "K5 Dashboard Homeroom and subjects")
  opts.on("-l", "--loaded_course", "Loaded Course with teacher and students")
  opts.on("-m", "--mastery_path", "Mastery Path Course")
  opts.on("-n", "--num_students=NUMSTUDENTS", Integer, "Number of students in course")
  opts.on("-p", "--blueprint", "Blueprint Course and Association")
  opts.on("-r", "--rubric", "Course with Outcome Rubric Assignment")
  opts.on("-s", "--submissions", "Course and Assignments and Submissions")
  opts.on("-t", "--sections", "Course with Students in Sections")
  opts.on_tail("-h", "--help", "Help") do
    puts opts
    exit
  end
end

begin
  option_parser.parse!(into: options)
rescue OptionParser::InvalidOption => e
  puts e.message
  puts option_parser.help
  exit 1
end
@course_name = options.key?(:course_name) ? options[:course_name] : "Play Course"
@number_of_students = options.key?(:num_students) ? options[:num_students] : 3
root_account_id = options.key?(:account_id) ? options[:account_id] : 2

if (@root_account = Account.find_by(id: root_account_id)).nil?
  puts "Invalid Root Account Id: #{root_account_id}"
  puts option_parser.help
  exit 1
end

options.except!(:course_name, :num_students, :account_id)

if options[:all_data]
  create_all_the_available_data
  exit 0
elsif options.empty?
  puts "A generation option must be specified."
  puts option_parser.help
  exit 1
end

options.each_key do |key|
  case key
  when :basic_course
    generate_course_with_students
  when :dated_assignments
    generate_course_with_dated_assignments
  when :assignment_groups
    generate_course_assignment_groups
  when :k5_dash
    generate_k5_dashboard
  when :loaded_course
    generate_fully_loaded_course
  when :mastery_path
    generate_mastery_path_course
  when :blueprint
    generate_bp_course_and_associations
  when :rubric
    generate_course_with_outcome_rubric
  when :submissions
    generate_course_and_submissions
  when :sections
    generate_sections
  when :course_pace
    generate_course_pace_course
  else raise "should never get here -- BIG FAIL"
  end
end

exit 0
