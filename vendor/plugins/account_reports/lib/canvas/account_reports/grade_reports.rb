#
# Copyright (C) 2012 Instructure, Inc.
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

module Canvas::AccountReports
  class GradeReports
    include Api
    include Canvas::ReportHelpers::DateHelper

    def initialize(account_report)
      @account_report = account_report
      @account = @account_report.account
      @domain_root_account = @account.root_account
      @term = api_find(@account.enrollment_terms, @account_report.parameters["enrollment_term"]) if @account_report.parameters && @account_report.parameters["enrollment_term"]
    end

    # retrieve the list of students for all active courses
    # for each student, iterate through all applicable assignments
    # for each assignment, find the submission, then iterate through all
    #   outcome alignments and find the outcome result
    # for each student-assignment-outcome pairing, generate a row
    #   based on the found outcome result
    # each row should include:
    # - student name
    # - student id
    # - assignment title
    # - assignment id
    # - submission date
    # - assignment score
    # - learning outcome name
    # - learning outcome id
    # - outcome result score
    def student_assignment_outcome_map
      students = @account.associated_courses.scoped(:conditions => {:workflow_state => 'available'}).map(&:participating_students).flatten.uniq
      total = students.length
      outcome_found = false
      result = FasterCSV.generate do |csv|
        csv << ['student name', 'student id', 'assignment title', 'assignment id', 'submission date', 'assignment score', 'learning outcome name', 'learning outcome id', 'attempt', 'outcome score', 'course name', 'course id', 'assignment url']
        students.each_with_index do |student, i|
          @account_report.update_attribute(:progress, (i.to_f/total)*100) if i%5 == 0
          student_submissions = student.submissions.to_a
          courses = student.enrollments.all_student.map(&:course)
          courses.each do |course|
            course.assignments.each do |assignment|
              submission = student_submissions.detect{|s| s.assignment_id == assignment.id }
              assignment.learning_outcome_tags.each do |outcome_tag|
                outcome = outcome_tag.learning_outcome
                next unless outcome.context == @account
                outcome_found = true
                outcome_result = outcome_tag.learning_outcome_results.find_by_user_id(student.id)
                arr = []
                arr << student.sortable_name
                arr << student.id
                arr << assignment.title
                arr << assignment.id
                arr << (submission ? (default_timezone_format(submission.submitted_at)) : nil)
                arr << (submission ? (submission.score rescue nil) : nil)
                arr << outcome.short_description
                arr << outcome.id
                arr << (outcome_result ? outcome_result.attempt : nil)
                arr << (outcome_result ? outcome_result.score : nil)
                arr << course.name
                arr << course.id
                arr << "https://#{HostUrl.context_host(course)}/courses/#{course.id}/assignments/#{assignment.id}"
                csv << arr
              end
            end
          end
        end
        csv << ['Not outcomes found'] unless outcome_found
      end
      Canvas::AccountReports.message_recipient(@account_report, I18n.t('account_reports.default.outcome.message',"Student-assignment-outcome mapping report successfully generated for %{account_name}",:account_name => @account.name), result)
      result
    end

    # retrieve the list of courses for the account
    # get a list of all students for the course
    # get the current grade and final grade for the student in that course
    # each row should include:
    # - student name
    # - student id
    # - student sis id
    # - course name
    # - course id
    # - course sis id
    # - section name
    # - section id
    # - section sis id
    # - term name
    # - term id
    # - term sis id
    # - student current score
    # - student final score

    def grade_export()
      term = @term
      name = term ? term.name : I18n.t('account_reports.default.all_terms', "All Terms")
      @account_report.parameters["extra_text"] = I18n.t('account_reports.default.extra_text', "For Term: %{term_name}", :term_name => name)
      students = StudentEnrollment.scoped(:include => {:course => :enrollment_term, :course_section => [], :user => :pseudonyms},
                                          :order => 'enrollment_terms.id, courses.id, enrollments.id',
                                          :conditions => {:root_account_id => @account.id,
                                                          'courses.workflow_state' => 'available', 'enrollments.workflow_state' => ['active', 'completed'] })
      students = students.scoped(:conditions => { 'courses.enrollment_term_id' => term}) if term

      result = FasterCSV.generate do |csv|
        csv << ['student name', 'student id', 'student sis', 'course', 'course id', 'course sis', 'section', 'section id', 'section sis', 'term', 'term id', 'term sis','current score', 'final score']
        students.each do |student|
          course = student.course
          course_section = student.course_section
          arr = []
          arr << student.user.name
          arr << student.user.id
          arr << student.user.sis_pseudonym_for(@account).try(:sis_user_id)
          arr << course.name
          arr << course.id
          arr << course.sis_source_id
          arr << course_section.name
          arr << course_section.id
          arr << course_section.sis_source_id
          arr << course.enrollment_term.name
          arr << course.enrollment_term.id
          arr << course.enrollment_term.sis_source_id
          arr << student.computed_current_score
          arr << student.computed_final_score
          csv << arr
        end
      end

      Canvas::AccountReports.message_recipient(@account_report, I18n.t('account_reports.default.grade.message',"Grade export successfully generated for term %{term_name}", :term_name => name), result)
      result
    end
  end
end
