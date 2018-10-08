#
# Copyright (C) 2012 - present Instructure, Inc.
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

require 'account_reports/report_helper'

module AccountReports

  class GradeReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
      include_deleted_objects

      if @account_report.has_parameter? "limiting_period"
        add_extra_text(I18n.t('account_reports.grades.limited',
                              'deleted objects limited by days specified;'))
      end
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
    # - enrollment status

    def grade_export()
      students = student_grade_scope
      students = add_term_scope(students, 'c')

      headers = []
      headers << I18n.t('student name')
      headers << I18n.t('student id')
      headers << I18n.t('student sis')
      headers << I18n.t('course')
      headers << I18n.t('course id')
      headers << I18n.t('course sis')
      headers << I18n.t('section')
      headers << I18n.t('section id')
      headers << I18n.t('section sis')
      headers << I18n.t('term')
      headers << I18n.t('term id')
      headers << I18n.t('term sis')
      headers << I18n.t('current score')
      headers << I18n.t('final score')
      headers << I18n.t('enrollment state')
      headers << I18n.t('unposted current score')
      headers << I18n.t('unposted final score')

      courses = root_account.all_courses
      courses = courses.where(:enrollment_term_id => term) if term

      write_report headers do |csv|
        course_ids = courses.order(:enrollment_term_id, :id).pluck(:id)
        course_ids.each_slice(1000) do |batched_course_ids|
          students.where(:course_id => batched_course_ids).preload(:root_account, :sis_pseudonym).find_in_batches do |student_chunk|
            users = student_chunk.map {|e| User.new(id: e.user_id)}.compact
            users.uniq!
            users_by_id = users.index_by(&:id)
            pseudonyms = load_cross_shard_logins(users, include_deleted: @include_deleted)
            student_chunk.each do |student|
              p = loaded_pseudonym(pseudonyms,
                                   users_by_id[student.user_id],
                                   include_deleted: @include_deleted,
                                   enrollment: student)
              next unless p
              arr = []
              arr << student["user_name"]
              arr << student["user_id"]
              arr << p.sis_user_id
              arr << student["course_name"]
              arr << student["course_id"]
              arr << student["course_sis_id"]
              arr << student["section_name"]
              arr << student["course_section_id"]
              arr << student["section_sis_id"]
              arr << student["term_name"]
              arr << student["term_id"]
              arr << student["term_sis_id"]
              arr << student["current_score"]
              arr << student["final_score"]
              arr << student["enroll_state"]
              arr << student["unposted_current_score"]
              arr << student["unposted_final_score"]
              csv << arr
            end
          end
        end
      end
    end

    def mgp_grade_export
      terms = @account_report.parameters[:enrollment_term_id].blank? ?
        root_account.enrollment_terms.active :
        root_account.enrollment_terms.where(id: @account_report.parameters[:enrollment_term_id])

      term_reports = terms.reduce({}) do |reports, term|
        reports[term.name] = mgp_term_csv(term)
        reports
      end

      send_report(term_reports)
    end

    def mgp_term_csv(term)
      students = student_grade_scope
      students = students.where(c: {enrollment_term_id: term})

      gp_set = term.grading_period_group
      unless gp_set
        not_found = Tempfile.open(%w[not-found csv])
        not_found.puts I18n.t("no grading periods configured for this term")
        not_found.close
        return not_found
      end
      grading_periods = gp_set.grading_periods.active.order(:start_date)

      headers = []
      headers << I18n.t('student name')
      headers << I18n.t('student id')
      headers << I18n.t('student sis')
      headers << I18n.t('course')
      headers << I18n.t('course id')
      headers << I18n.t('course sis')
      headers << I18n.t('section')
      headers << I18n.t('section id')
      headers << I18n.t('section sis')
      headers << I18n.t('term')
      headers << I18n.t('term id')
      headers << I18n.t('term sis')
      headers << I18n.t('grading period set')
      headers << I18n.t('grading period set id')
      grading_periods.each { |gp|
        headers << I18n.t('%{name} grading period id', name: gp.title)
        headers << I18n.t('%{name} current score', name: gp.title)
        headers << I18n.t('%{name} final score', name: gp.title)
        headers << I18n.t('%{name} unposted current score', name: gp.title)
        headers << I18n.t('%{name} unposted final score', name: gp.title)
      }
      headers << I18n.t('current score')
      headers << I18n.t('final score')
      headers << I18n.t('enrollment state')
      headers << I18n.t('unposted current score')
      headers << I18n.t('unposted final score')

      generate_and_run_report headers do |csv|
        course_ids = root_account.all_courses.where(:enrollment_term_id => term).order(:id).pluck(:id)
        course_ids.each_slice(1000) do |batched_course_ids|
          students.where(:course_id => batched_course_ids).preload(:root_account, :sis_pseudonym).find_in_batches do |student_chunk|
            users = student_chunk.map {|e| User.new(id: e.user_id)}.compact
            users.uniq!
            users_by_id = users.index_by(&:id)
            pseudonyms = load_cross_shard_logins(users, include_deleted: @include_deleted)
            students_by_course = student_chunk.group_by { |x| x.course_id }
            students_by_course.each do |course_id, course_students|
              scores = indexed_scores(course_students, grading_periods)
              course_students.each do |student|
                p = loaded_pseudonym(pseudonyms,
                                     users_by_id[student.user_id],
                                     include_deleted: @include_deleted,
                                     enrollment: student)
                next unless p
                arr = []
                arr << student["user_name"]
                arr << student["user_id"]
                arr << p.sis_user_id
                arr << student["course_name"]
                arr << student["course_id"]
                arr << student["course_sis_id"]
                arr << student["section_name"]
                arr << student["course_section_id"]
                arr << student["section_sis_id"]
                arr << student["term_name"]
                arr << student["term_id"]
                arr << student["term_sis_id"]
                arr << gp_set.title
                arr << gp_set.id
                grading_periods.each do |gp|
                  scores_for_student = grading_period_scores_for_student(student, gp, scores)
                  arr << gp.id
                  arr << scores_for_student[:current_score]
                  arr << scores_for_student[:final_score]
                  arr << scores_for_student[:unposted_current_score]
                  arr << scores_for_student[:unposted_final_score]
                end
                arr << student["current_score"]
                arr << student["final_score"]
                arr << student["enroll_state"]
                arr << student["unposted_current_score"]
                arr << student["unposted_final_score"]
                csv << arr
              end
            end
          end
        end
      end
    end

    private

    def indexed_scores(students, grading_periods)
      Score.where(
        enrollment_id: students.map(&:enrollment_id),
        grading_period_id: grading_periods.map(&:id)
      ).active.select(
        :enrollment_id,
        :grading_period_id,
        :current_score,
        :final_score,
        :unposted_current_score,
        :unposted_final_score
      ).index_by { |score| "#{score[:enrollment_id]}:#{score[:grading_period_id]}" }
    end

    def grading_period_scores_for_student(student, grading_period, scores)
      scores["#{student['enrollment_id']}:#{grading_period.id}"] || {}
    end

    def student_grade_scope
      students = root_account.enrollments.
        select("u.name AS user_name, enrollments.user_id, enrollments.course_id,
                c.name AS course_name,
                enrollments.root_account_id, enrollments.sis_pseudonym_id,
                c.sis_source_id AS course_sis_id, s.name AS section_name,
                enrollments.course_section_id, s.sis_source_id AS section_sis_id,
                enrollments.id AS enrollment_id,
                t.name AS term_name, t.id AS term_id,
                t.sis_source_id AS term_sis_id,
                sc.current_score,
                sc.final_score,
                sc.unposted_current_score,
                sc.unposted_final_score,
           CASE WHEN enrollments.workflow_state = 'active' THEN 'active'
                WHEN enrollments.workflow_state = 'completed' THEN 'concluded'
                WHEN enrollments.workflow_state = 'inactive' THEN 'inactive'
                WHEN enrollments.workflow_state = 'deleted' THEN 'deleted' END AS enroll_state").
        order("t.id, c.id, enrollments.id").
        joins("INNER JOIN #{User.quoted_table_name} u ON enrollments.user_id = u.id
               INNER JOIN #{Course.quoted_table_name} c ON c.id = enrollments.course_id
               INNER JOIN #{EnrollmentTerm.quoted_table_name} t ON c.enrollment_term_id = t.id
               INNER JOIN #{CourseSection.quoted_table_name} s ON enrollments.course_section_id = s.id
               LEFT JOIN #{Score.quoted_table_name} sc ON sc.enrollment_id = enrollments.id AND sc.course_score IS TRUE").
        where("enrollments.type='StudentEnrollment'")

      if @include_deleted
        students = students.where("enrollments.workflow_state IN ('active', 'completed', 'inactive', 'deleted')")
        if @account_report.parameters.has_key? 'limiting_period'
          limiting_period = @account_report.parameters['limiting_period'].to_i
          students = students.where("enrollments.workflow_state = 'active'
                                    OR c.conclude_at >= ?
                                    OR (enrollments.workflow_state IN ('inactive', 'deleted')
                                    AND enrollments.updated_at >= ?)",
                                    limiting_period.days.ago, limiting_period.days.ago)
        end
      else
        students = students.where(
          "c.workflow_state='available'
           AND enrollments.workflow_state IN ('active', 'completed')
           AND sc.workflow_state <> 'deleted'")
      end

      students = add_course_sub_account_scope(students, 'c')
    end
  end
end
