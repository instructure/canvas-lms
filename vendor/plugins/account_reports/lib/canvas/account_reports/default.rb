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
  module Default

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
    def self.student_assignment_outcome_map_csv(account_report)
      students = account_report.account.associated_courses.scoped(:conditions => {:workflow_state => 'available'}).map(&:participating_students).flatten.uniq
      total = students.length
      outcome_found = false
      result = FasterCSV.generate do |csv|
        csv << ['student name', 'student id', 'assignment title', 'assignment id', 'submission date', 'assignment score', 'learning outcome name', 'learning outcome id', 'attempt', 'outcome score', 'course name', 'course id', 'assignment url']
        students.each_with_index do |student, i|
          account_report.update_attribute(:progress, (i.to_f/total)*100) if i%5 == 0
          student_submissions = student.submissions.to_a
          courses = student.enrollments.all_student.map(&:course)
          courses.each do |course|
            course.assignments.each do |assignment|
              submission = student_submissions.detect{|s| s.assignment_id == assignment.id }
              assignment.learning_outcome_tags.each do |outcome_tag|
                outcome = outcome_tag.learning_outcome
                next unless outcome.context == account_report.account
                outcome_found = true
                outcome_result = outcome_tag.learning_outcome_results.find_by_user_id(student.id)
                arr = []
                arr << student.sortable_name
                arr << student.id
                arr << assignment.title
                arr << assignment.id
                arr << (submission ? (submission.submitted_at.iso8601 rescue nil) : nil)
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
      Canvas::AccountReports.message_recipient(account_report, I18n.t('account_reports.default.outcome.message',"Student-assignment-outcome mapping report successfully generated for %{account_name}", :account_name => account_report.account.name), result)
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

    def self.grade_export_csv(account_report)
      term = account_report.parameters["enrollment_term"].presence
      name = term ? account_report.account.enrollment_terms.find(term).name : I18n.t('account_reports.default.all_terms', "All Terms")
      account_report.parameters["extra_text"] = I18n.t('account_reports.default.extra_text', "For Term: %{term_name}", :term_name => name)
      students = StudentEnrollment.scoped(:include => {:course => :enrollment_term, :course_section => [], :user => :pseudonyms}, :order => 'enrollment_terms.id, courses.id, enrollments.id', :conditions => { :root_account_id => account_report.account.id, 'courses.workflow_state' => 'available', 'enrollments.workflow_state' => ['active', 'completed'] })
      students = students.scoped(:conditions => { 'courses.enrollment_term_id' => term}) if term

      result = FasterCSV.generate do |csv|
        csv << ['student name', 'student id', 'student sis', 'course', 'course id', 'course sis', 'section', 'section id', 'section sis', 'term', 'term id', 'term sis','current score', 'final score']
        students.each do |student|
          course = student.course
          course_section = student.course_section
          arr = []
          arr << student.user.name
          arr << student.user.id
          arr << student.user.sis_pseudonym_for(account_report.account).try(:sis_user_id)
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

      Canvas::AccountReports.message_recipient(account_report, I18n.t('account_reports.default.grade.message',"Grade export successfully generated for term %{term_name}", :term_name => name), result)
      result
    end

    SIS_CSV_REPORTS = ["users", "accounts", "terms", "courses", "sections", "enrollments", "groups", "group_membership", "xlist"]

    def self.sis_export_csv(account_report)
      term = account_report.parameters["enrollment_term"].presence
      reports = SIS_CSV_REPORTS & account_report.parameters.keys

      if reports.length == 0
        Canvas::AccountReports.message_recipient(account_report, "SIS export report for #{account_report.account.name} has been successfully generated.")
      elsif reports.length == 1
        csv = self.send(reports.first, term, account_report.account)
        Canvas::AccountReports.message_recipient(account_report, "SIS export report for #{account_report.account.name} has been successfully generated.", csv)
        csv
      else
        csvs = {}
        reports.each do |report_name|
          csvs[report_name] = self.send(report_name, term, account_report.account)
        end
        Canvas::AccountReports.message_recipient(account_report, "SIS export reports for #{account_report.account.name} have been successfully generated.", csvs)
        csvs
      end
    end

    def self.users(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['user_id','login_id', 'password','first_name','last_name','email', 'status']
        pseudonym = account.pseudonyms.active.scoped(:include => [ :user], :conditions => "sis_user_id IS NOT NULL")
        pseudonym.each do |i|
          row = []
          row << i.sis_user_id
          row << i.login
          row << nil
          row << i.user.first_name
          row << i.user.last_name
          row << i.user.email
          row << i.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def self.accounts(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['account_id','parent_account_id', 'name','status']
        Account.find_each(:select => "accounts.*, parent_account.sis_source_id as parent_sis_source_id",
                          :joins => "INNER JOIN accounts as parent_account ON accounts.parent_account_id = parent_account.id",
                          :conditions => "accounts.sis_source_id IS NOT NULL and accounts.workflow_state = 'active' and accounts.root_account_id = #{account.id}") do |a|
          row = []
          row << a.sis_source_id
          row << a.parent_sis_source_id
          row << a.name
          row << a.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def self.terms(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['term_id','name','status', 'start_date', 'end_date']
        terms = account.enrollment_terms.scoped(:conditions => "sis_source_id IS NOT NULL")
        terms.each do |t|
          row = []
          row << t.sis_source_id
          row << t.name
          row << t.workflow_state
          row << t.start_at.try(:iso8601)
          row << t.end_at.try(:iso8601)
          csv << row
        end
      end
      list_csv
    end

    def self.courses(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['course_id','short_name', 'long_name','account_id','term_id', 'status', 'start_date', 'end_date']
        if term
          term = " and enrollment_term_id =#{term}"
        else
          term = ""
        end
        courses = account.all_courses.active.scoped(:conditions => "sis_source_id IS NOT NULL#{term}", :include => [:account, :enrollment_term])
        courses.find_each do |c|
          row = []
          row << c.sis_source_id
          row << c.course_code
          row << c.name
          row << c.account.try(:sis_source_id)
          row << c.enrollment_term.try(:sis_source_id)
          row << 'active'
          if c.restrict_enrollments_to_course_dates
            row << c.start_at.try(:iso8601)
            row << c.conclude_at.try(:iso8601)
          else
            row << nil
            row << nil
          end
          csv << row
        end
      end
      list_csv
    end

    def self.sections(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['section_id', 'course_id', 'name', 'status', 'start_date', 'end_date', 'account_id']

        if term
          term = " and courses.enrollment_term_id =#{term}"
        else
          term = ""
        end

        sections = account.course_sections.active.scoped(:include => [:course, :account, :nonxlist_course], :conditions => "course_sections.sis_source_id IS NOT NULL#{term}")
        sections.find_each do |s|
          row = []
          row << s.sis_source_id
          row << (s.nonxlist_course || s.course).sis_source_id
          row << s.name
          row << s.workflow_state
          if s.restrict_enrollments_to_section_dates
            row << s.start_at.try(:iso8601)
            row << s.end_at.try(:iso8601)
          else
            row << nil
            row << nil
          end
          row << s.account.try(:sis_source_id)
          csv << row
        end
      end
      list_csv
    end

    def self.enrollments(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['course_id', 'user_id', 'role', 'section_id', 'status', 'associated_user_id']
        if term
          term = " and courses.enrollment_term_id = #{term}"
        else
          term = ""
        end
        Enrollment.find_each(:select => "enrollments.*, courses.sis_source_id as course_sis_id,
                                        course_sections.sis_source_id as course_section_sis_id,
                                        pseudonyms.sis_user_id as pseudonym_sis_id,
                                        associated_user.sis_user_id as associated_user_sis_id,
                                        CASE WHEN enrollments.type = 'TeacherEnrollment' THEN 'teacher'
                                             WHEN enrollments.type='TaEnrollment' THEN 'ta'
                                             WHEN enrollments.type='StudentEnrollment' THEN 'student'
                                             WHEN enrollments.type='ObserverEnrollment' THEN 'observer' END as enrollment_type",
                             :joins => "INNER JOIN courses on courses.id = enrollments.course_id
                                        INNER JOIN course_sections on course_sections.id = enrollments.course_section_id
                                        INNER JOIN pseudonyms ON pseudonyms.user_id=enrollments.user_id
                                        AND pseudonyms.sis_user_id IS NOT NULL AND pseudonyms.account_id=#{account.id}
                                        LEFT OUTER JOIN pseudonyms as associated_user on associated_user.user_id = enrollments.associated_user_id
                                        AND pseudonyms.sis_user_id IS NOT NULL AND pseudonyms.account_id=#{account.id}",
                             :conditions => "enrollments.root_account_id = #{account.id}
                                             and enrollments.workflow_state = 'active'
                                             and pseudonyms.sis_user_id IS NOT NULL
                                             and (courses.sis_source_id IS NOT NULL or course_sections.sis_source_id IS NOT NULL)
                                             #{term}") do |e|
          row = []
          row << e.course_sis_id
          row << e.pseudonym_sis_id
          row << e.enrollment_type
          row << e.course_section_sis_id
          row << 'active'
          row << e.associated_user_sis_id
          csv << row
        end
      end
      list_csv
    end

    def self.groups(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['group_id', 'account_id', 'name', 'status']
        Group.find_each(:select => "groups.*, accounts.sis_source_id as account_sis_id",
                        :joins => "INNER JOIN accounts on accounts.id = groups.account_id",
                        :conditions => "groups.sis_source_id IS NOT NULL and groups.root_account_id = #{account.id}") do |g|
          row = []
          row << g.sis_source_id
          row << g.account_sis_id
          row << g.name
          row << g.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def self.group_membership(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['group_id', 'user_id', 'status']
        GroupMembership.find_each(:select => "group_memberships.*, groups.sis_source_id as group_sis_id, pseudonyms.sis_user_id as users_sis_id",
                                  :joins => "INNER JOIN groups on groups.id = group_memberships.group_id
                                             INNER JOIN pseudonyms ON pseudonyms.user_id=group_memberships.user_id
                                             AND pseudonyms.sis_user_id IS NOT NULL AND pseudonyms.account_id=#{account.id}",
                                  :conditions => "groups.root_account_id = #{account.id}
                                                  and group_memberships.sis_batch_id IS NOT NULL
                                                  and group_memberships.workflow_state = 'accepted'") do |gm|
          row = []
          row << gm.group_sis_id
          row << gm.users_sis_id
          row << gm.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def self.xlist(term, account)
      list_csv = FasterCSV.generate do |csv|
        csv << ['xlist_course_id','section_id', 'status']
        if term
          term = " and courses.enrollment_term_id =#{term}"
        else
          term = ""
        end
        xlists = account.course_sections.active.scoped(:include => [:course, :account, :nonxlist_course], :conditions => "courses.sis_source_id IS NOT NULL AND course_sections.sis_source_id IS NOT NULL AND course_sections.nonxlist_course_id IS NOT NULL#{term}")
        xlists.find_each do |x|
          row = []
          row << x.course.sis_source_id
          row << x.sis_source_id
          row << x.workflow_state
          csv << row
        end
      end
      list_csv
    end
  end
end