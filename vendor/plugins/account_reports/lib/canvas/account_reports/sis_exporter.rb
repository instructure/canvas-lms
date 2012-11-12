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
  class SisExporter
    include Api
    include Canvas::ReportHelpers::DateHelper

    SIS_CSV_REPORTS = ["users", "accounts", "terms", "courses", "sections", "enrollments", "groups", "group_membership", "xlist"]

    def initialize(account_report, params = {})
      @account_report = account_report
      @account = @account_report.account
      @domain_root_account = @account.root_account
      @term = api_find(@account.enrollment_terms, @account_report.parameters["enrollment_term"]) if @account_report.parameters["enrollment_term"].presence
      @reports = SIS_CSV_REPORTS & @account_report.parameters.keys
      @sis_format = params[:sis_format]
    end

    def csv
      if @reports.length == 0
        Canvas::AccountReports.message_recipient(@account_report, "SIS export report for #{@account.name} has been successfully generated.")
      elsif @reports.length == 1
        csv = self.send(@reports.first)
        Canvas::AccountReports.message_recipient(@account_report, "SIS export report for #{@account.name} has been successfully generated.", csv)
        csv
      else
        csvs = {}

        @reports.each do |report_name|
          csvs[report_name] = self.send(report_name)
        end
        Canvas::AccountReports.message_recipient(@account_report, "SIS export reports for #{@account.name} have been successfully generated.", csvs)
        csvs
      end
    end

    def users
      list_csv = FasterCSV.generate do |csv|
        headers = ['user_id','login_id', 'password','first_name','last_name','email', 'status']
        unless @sis_format
          headers = ['canvas_user_id','user_id','login_id','first_name','last_name','email', 'status']
        end
        csv << headers
        users = @account.pseudonyms.active.scoped(:include => :user)
        users = users.scoped(:conditions => 'sis_user_id IS NOT NULL') if @sis_format
        users.find_each do |i|
          row = []
          row << i.user_id unless @sis_format
          row << i.sis_user_id
          row << i.login
          row << nil if @sis_format
          row << i.user.first_name
          row << i.user.last_name
          row << i.user.email
          row << i.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def accounts
      list_csv = FasterCSV.generate do |csv|
        headers = ['account_id','parent_account_id', 'name','status']
        headers = ['canvas_account_id','account_id','canvas_parent_id','parent_account_id', 'name','status'] unless @sis_format
        csv << headers
        accounts = @account.all_accounts.active.scoped(
          :select => "accounts.*, parent_account.id as parent_id, parent_account.sis_source_id as parent_sis_source_id",
          :joins => "INNER JOIN accounts as parent_account ON accounts.parent_account_id = parent_account.id")
        accounts = accounts.scoped(:conditions => "accounts.sis_source_id IS NOT NULL") if @sis_format
        accounts.find_each do |a|
          row = []
          row << a.id unless @sis_format
          row << a.sis_source_id
          row << a.parent_id unless @sis_format
          row << a.parent_sis_source_id
          row << a.name
          row << a.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def terms
      list_csv = FasterCSV.generate do |csv|
        headers = ['term_id','name','status', 'start_date', 'end_date']
        headers.unshift 'canvas_term_id' unless @sis_format
        csv << headers
        terms = @account.enrollment_terms.active
        terms = terms.scoped(:conditions => "sis_source_id IS NOT NULL") if @sis_format
        terms.each do |t|
          row = []
          row << t.id unless @sis_format
          row << t.sis_source_id
          row << t.name
          row << t.workflow_state
          row << default_timezone_format(t.start_at)
          row << default_timezone_format(t.end_at)
          csv << row
        end
      end
      list_csv
    end

    def courses
      list_csv = FasterCSV.generate do |csv|
        headers = ['course_id','short_name', 'long_name','account_id','term_id', 'status', 'start_date', 'end_date']
        headers.unshift 'canvas_course_id' unless @sis_format
        csv << headers
        courses = @account.all_courses.active.scoped(
          :include => [:account, :enrollment_term],
          :select => "courses.*,
                 CASE WHEN courses.workflow_state = 'claimed' THEN 'unpublished'
                      WHEN courses.workflow_state = 'created' THEN 'unpublished'
                      WHEN courses.workflow_state = 'completed' THEN 'concluded'
                      WHEN courses.workflow_state = 'available' THEN 'active' END as course_state")
        courses = courses.scoped(:conditions => ["enrollment_term_id=?", @term]) if @term
        courses = courses.scoped(:conditions => "sis_source_id IS NOT NULL") if @sis_format

        courses.find_each do |c|
          row = []
          row << c.id unless @sis_format
          row << c.sis_source_id
          row << c.course_code
          row << c.name
          row << c.account.try(:sis_source_id)
          row << c.enrollment_term.try(:sis_source_id)
          row << 'active' if @sis_format
          row << c.course_state unless @sis_format
          if c.restrict_enrollments_to_course_dates
            row << default_timezone_format(c.start_at)
            row << default_timezone_format(c.conclude_at)
          else
            row << nil
            row << nil
          end
          csv << row
        end
      end
      list_csv
    end

    def sections
      list_csv = FasterCSV.generate do |csv|
        headers = ['section_id', 'course_id', 'name', 'status', 'start_date', 'end_date', 'account_id']
        unless @sis_format
          headers = [ 'canvas_section_id', 'section_id', 'canvas_course_id', 'course_id', 'name', 'status', 'start_date', 'end_date', 'canvas_account_id', 'account_id']
        end
        csv << headers
        sections = @account.course_sections.active.scoped(
          :select => "course_sections.*,
                      Coalesce(non_xlist_courses.sis_source_id, real_courses.sis_source_id) as section_course_sis_id,
                      accounts.sis_source_id as account_sis_id",
          :joins => "INNER JOIN courses as real_courses ON course_sections.course_id = real_courses.id
                     LEFT OUTER JOIN courses as non_xlist_courses ON course_sections.nonxlist_course_id = non_xlist_courses.id
                     LEFT OUTER JOIN accounts on course_sections.account_id = accounts.id")
        sections = sections.scoped(:conditions => ["real_courses.enrollment_term_id=?", @term]) if @term
        sections = sections.scoped(:conditions => "course_sections.sis_source_id IS NOT NULL
                                                   and (non_xlist_courses.sis_source_id IS NOT NULL
                                                   or real_courses.sis_source_id IS NOT NULL)") if @sis_format
        sections.find_each do |s|
          row = []
          row << s.id unless @sis_format
          row << s.sis_source_id
          row << (s.nonxlist_course_id || s.course_id) unless @sis_format
          row << s.section_course_sis_id
          row << s.name
          row << s.workflow_state
          if s.restrict_enrollments_to_section_dates
            row << default_timezone_format(s.start_at)
            row << default_timezone_format(s.end_at)
          else
            row << nil
            row << nil
          end
          row << s.account_id unless @sis_format
          row << s.try(:account_sis_id)
          csv << row
        end
      end
      list_csv
    end

    def enrollments
      list_csv = FasterCSV.generate do |csv|
        headers = ['course_id', 'user_id', 'role', 'section_id', 'status', 'associated_user_id']
        unless @sis_format
          headers = ['canvas_course_id', 'course_id', 'canvas_user_id', 'user_id', 'role', 'canvas_section_id', 'section_id', 'status', 'canvas_associated_user_id', 'associated_user_id']
        end
        csv << headers
        enrollments = @account.enrollments.active.scoped(
          :select => "enrollments.*, courses.sis_source_id as course_sis_id,
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
                     LEFT OUTER JOIN pseudonyms as associated_user on associated_user.user_id = enrollments.associated_user_id
                     AND associated_user.account_id = enrollments.root_account_id",
          :conditions => "pseudonyms.account_id = enrollments.root_account_id
                          AND enrollments.workflow_state = 'active'")
        enrollments = enrollments.scoped(:conditions => ["courses.enrollment_term_id = ?", @term]) if @term
        enrollments = enrollments.scoped(:conditions => "pseudonyms.sis_user_id IS NOT NULL
                                                         AND (courses.sis_source_id IS NOT NULL OR course_sections.sis_source_id IS NOT NULL)") if @sis_format
        enrollments.find_each do |e|
          row = []
          row << e.course_id unless @sis_format
          row << e.course_sis_id
          row << e.user_id unless @sis_format
          row << e.pseudonym_sis_id
          row << e.enrollment_type
          row << e.course_section_id unless @sis_format
          row << e.course_section_sis_id
          row << 'active'
          row << e.associated_user_id unless @sis_format
          row << e.associated_user_sis_id
          csv << row
        end
      end
      list_csv
    end

    def groups
      list_csv = FasterCSV.generate do |csv|
        headers = ['group_id', 'account_id', 'name', 'status']
        unless @sis_format
          headers = ['canvas_group_id', 'group_id', 'canvas_account_id', 'account_id', 'name', 'status']
        end
        csv << headers
        groups = @account.all_groups.active.scoped(:select => "groups.*, accounts.sis_source_id as account_sis_id",
                                                   :joins => "INNER JOIN accounts on accounts.id = groups.account_id")
        groups = groups.scoped(:conditions => "groups.sis_source_id IS NOT NULL") if @sis_format
        groups.find_each do |g|
          row = []
          row << g.id unless @sis_format
          row << g.sis_source_id
          row << g.account_id unless @sis_format
          row << g.account_sis_id
          row << g.name
          row << g.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def group_membership
      list_csv = FasterCSV.generate do |csv|
        headers = ['group_id', 'user_id', 'status']
        unless @sis_format
          headers = ['canvas_group_id', 'group_id','canvas_user_id', 'user_id', 'status']
        end
        csv << headers
        group_members = @account.all_groups.active.scoped(:select => "groups.*, group_memberships.*, pseudonyms.sis_user_id as user_sis_id",
                                                          :joins => "INNER JOIN group_memberships on groups.id = group_memberships.group_id
                                                                 INNER JOIN pseudonyms ON pseudonyms.user_id=group_memberships.user_id",
                                                          :conditions => "pseudonyms.account_id = groups.root_account_id
                                                                      AND group_memberships.workflow_state in ('accepted', 'invited')")
        group_members = group_members.scoped(:conditions => "pseudonyms.sis_user_id IS NOT NULL
                                                             AND group_memberships.sis_batch_id IS NOT NULL
                                                             AND group_memberships.workflow_state in ('accepted')") if @sis_format
        group_members.find_each do |gm|
          row = []
          row << gm.group_id  unless @sis_format
          row << gm.sis_source_id
          row << gm.user_id  unless @sis_format
          row << gm.user_sis_id
          row << gm.workflow_state
          csv << row
        end
      end
      list_csv
    end

    def xlist
      list_csv = FasterCSV.generate do |csv|
        headers = ['xlist_course_id', 'section_id', 'status']
        unless @sis_format
          headers = ['canvas_xlist_course_id', 'xlist_course_id', 'canvas_section_id', 'section_id', 'status']
        end
        csv << headers
        cross_listings = @account.course_sections.active.scoped(:include => [:course, :account, :nonxlist_course],
                                                                :conditions => "course_sections.nonxlist_course_id IS NOT NULL")
        cross_listings = cross_listings.scoped(:conditions => ["courses.enrollment_term_id=?", @term]) if @term
        cross_listings = cross_listings.scoped(:conditions => "courses.sis_source_id IS NOT NULL AND course_sections.sis_source_id IS NOT NULL") if @sis_format
        cross_listings.find_each do |x|
          row = []
          row << x.course_id unless @sis_format
          row << x.course.sis_source_id
          row << x.id unless @sis_format
          row << x.sis_source_id
          row << x.workflow_state
          csv << row
        end
      end
      list_csv
    end
  end
end
