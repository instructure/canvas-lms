#
# Copyright (C) 2012 - 2015 Instructure, Inc.
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
  class SisExporter
    include ReportHelper

    SIS_CSV_REPORTS = ["users", "accounts", "terms", "courses", "sections",
                       "enrollments", "groups", "group_membership",
                       "group_categories", "xlist", "user_observers", "admins"].freeze

    def initialize(account_report, params = {})
      @account_report = account_report
      @reports = SIS_CSV_REPORTS & @account_report.parameters.select { |_k, v| value_to_boolean(v) }.keys
      @sis_format = params[:sis_format]
      @created_by_sis = @account_report.parameters['created_by_sis']
      extra_text_term(@account_report)
      include_deleted_objects
    end

    def csv
      files = ""
      @reports.each do |report_name|
        files << "#{report_name} "
      end
      add_extra_text(I18n.t(
        'account_reports.sis_exporter.reports',
        'Reports: %{files}',
        :files => files
      ))

      if @reports.length == 0
        send_report()
      elsif @reports.length == 1
        csv = self.send(@reports.first)
        send_report(csv)
      else
        csvs = {}

        @reports.each do |report_name|
          csvs[report_name] = self.send(report_name)
        end
        send_report(csvs)
        csvs
      end
    end

    def users
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['user_id', 'integration_id', 'authentication_provider_id',
                   'login_id', 'password', 'first_name', 'last_name', 'full_name',
                   'sortable_name', 'short_name', 'email', 'status']
      else # provisioning_report
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_user_id', 'canvas_user_id')
        headers << I18n.t('#account_reports.report_header_user__id', 'user_id')
        headers << I18n.t('#account_reports.report_header_integration_id', 'integration_id')
        headers << I18n.t('#account_reports.report_header_authentication_provider_id', 'authentication_provider_id')
        headers << I18n.t('#account_reports.report_header_login_id', 'login_id')
        headers << I18n.t('#account_reports.report_header_first_name', 'first_name')
        headers << I18n.t('#account_reports.report_header_last_name', 'last_name')
        headers << I18n.t('#account_reports.report_header_full_name', 'full_name')
        headers << I18n.t('#account_reports.report_header_sortable_name', 'sortable_name')
        headers << I18n.t('#account_reports.report_header_user_short_name', 'short_name')
        headers << I18n.t('#account_reports.report_header_email', 'email')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('created_by_sis')
      end

      users = root_account.pseudonyms.except(:preload).joins(:user).select(
        "pseudonyms.id, pseudonyms.sis_user_id, pseudonyms.user_id, pseudonyms.sis_batch_id,
         pseudonyms.integration_id,pseudonyms.authentication_provider_id,pseudonyms.unique_id,
         pseudonyms.workflow_state, users.sortable_name,users.updated_at AS user_updated_at,
         users.name, users.short_name").
        where("NOT EXISTS (SELECT user_id
                           FROM #{Enrollment.quoted_table_name} e
                           WHERE e.type = 'StudentViewEnrollment'
                           AND e.user_id = pseudonyms.user_id)")

      users = users.where.not(sis_user_id: nil) if @sis_format
      users = users.where.not(pseudonyms: {sis_batch_id: nil}) if @created_by_sis

      if @include_deleted
        users.where!("pseudonyms.workflow_state<>'deleted' OR pseudonyms.sis_user_id IS NOT NULL")
      else
        users.where!("pseudonyms.workflow_state<>'deleted'")
      end

      users = add_user_sub_account_scope(users)

      generate_and_run_report headers do |csv|
        users.find_in_batches do |batch|
          emails = Shard.partition_by_shard(batch.map(&:user_id)) do |user_ids|
            CommunicationChannel.
              email.
              unretired.
              select([:user_id, :path]).
              where(user_id: user_ids).
              order('user_id, position ASC').
              distinct_on(:user_id)
          end.index_by(&:user_id)

          batch.each do |u|
            row = []
            row << u.user_id unless @sis_format
            row << u.sis_user_id
            row << u.integration_id
            row << u.authentication_provider_id
            row << u.unique_id
            row << nil if @sis_format
            name_parts = User.name_parts(u.sortable_name, likely_already_surname_first: true)
            row << name_parts[0] || '' # first name
            row << name_parts[1] || '' # last name
            row << u.name
            row << u.sortable_name
            row << u.short_name
            row << emails[u.user_id].try(:path)
            row << u.workflow_state
            row << u.sis_batch_id? unless @sis_format
            csv << row
          end
        end
      end
    end

    def accounts
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['account_id', 'parent_account_id', 'name', 'status']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_account_id', 'canvas_account_id')
        headers << I18n.t('#account_reports.report_header_account_id', 'account_id')
        headers << I18n.t('#account_reports.report_header_canvas_parent_id', 'canvas_parent_id')
        headers << I18n.t('#account_reports.report_header_parent_account_id', 'parent_account_id')
        headers << I18n.t('#account_reports.report_header_name', 'name')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('created_by_sis')
      end
      accounts = root_account.all_accounts.
        select("accounts.*, pa.id AS parent_id,
                pa.sis_source_id AS parent_sis_source_id").
        joins("INNER JOIN #{Account.quoted_table_name} AS pa ON accounts.parent_account_id=pa.id")

      accounts = accounts.where.not(accounts: {sis_source_id: nil}) if @sis_format
      accounts = accounts.where.not(accounts: {sis_batch_id: nil}) if @created_by_sis

      if @include_deleted
        accounts.where!("accounts.workflow_state<>'deleted' OR accounts.sis_source_id IS NOT NULL")
      else
        accounts.where!("accounts.workflow_state<>'deleted'")
      end

      if account != root_account
        # this does not give the full tree pf sub accounts, just the direct children.
        accounts.where!(:accounts => {:parent_account_id => account})
      end

      generate_and_run_report headers do |csv|
        accounts.find_each do |a|
          row = []
          row << a.id unless @sis_format
          row << a.sis_source_id
          row << a.parent_id unless @sis_format
          row << a.parent_sis_source_id
          row << a.name
          row << a.workflow_state
          row << a.sis_batch_id? unless @sis_format
          csv << row
        end
      end
    end

    def terms
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['term_id', 'name', 'status', 'start_date', 'end_date']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_term_id', 'canvas_term_id')
        headers << I18n.t('#account_reports.report_header_term__id', 'term_id')
        headers << I18n.t('#account_reports.report_header_name', 'name')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('#account_reports.report_header_start__date', 'start_date')
        headers << I18n.t('#account_reports.report_header_end__date', 'end_date')
        headers << I18n.t('created_by_sis')
      end
      terms = root_account.enrollment_terms
      terms = terms.where.not(sis_source_id: nil) if @sis_format
      terms = terms.where.not(enrollment_terms: {sis_batch_id: nil}) if @created_by_sis

      if @include_deleted
        terms = terms.where("workflow_state<>'deleted' OR sis_source_id IS NOT NULL")
      else
        terms = terms.where("workflow_state<>'deleted'")
      end

      generate_and_run_report headers do |csv|
        terms.find_each do |t|
          row = []
          row << t.id unless @sis_format
          row << t.sis_source_id
          row << t.name
          row << t.workflow_state
          row << default_timezone_format(t.start_at)
          row << default_timezone_format(t.end_at)
          row << t.sis_batch_id? unless @sis_format
          csv << row
        end
      end
    end

    def courses
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['course_id', 'integration_id', 'short_name', 'long_name',
                   'account_id', 'term_id', 'status', 'start_date', 'end_date', 'course_format']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_course_id', 'canvas_course_id')
        headers << I18n.t('#account_reports.report_header_course__id', 'course_id')
        headers << I18n.t('#account_reports.report_header_integration_id', 'integration_id')
        headers << I18n.t('#account_reports.report_header_short__name', 'short_name')
        headers << I18n.t('#account_reports.report_header_long__name', 'long_name')
        headers << I18n.t('#account_reports.report_header_canvas_account_id', 'canvas_account_id')
        headers << I18n.t('#account_reports.report_header_account_id', 'account_id')
        headers << I18n.t('#account_reports.report_header_canvas_term_id', 'canvas_term_id')
        headers << I18n.t('#account_reports.report_header_term__id', 'term_id')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('#account_reports.report_header_start__date', 'start_date')
        headers << I18n.t('#account_reports.report_header_end__date', 'end_date')
        headers << I18n.t('#account_reports.report_header_course_format', 'course_format')
        headers << I18n.t('created_by_sis')
      end

      courses = root_account.all_courses.preload(:account, :enrollment_term)
      courses = courses.where.not(courses: {sis_source_id: nil}) if @sis_format
      courses = courses.where.not(courses: {sis_batch_id: nil}) if @created_by_sis

      if @include_deleted
        courses.where!("(courses.workflow_state='deleted' AND courses.updated_at > ?)
                          OR courses.workflow_state<>'deleted'
                          OR courses.sis_source_id IS NOT NULL", 120.days.ago)
      else
        courses.where!("courses.workflow_state<>'deleted' AND courses.workflow_state<>'completed'")
      end

      courses = add_course_sub_account_scope(courses)
      courses = add_term_scope(courses)

      course_state_sub = {'claimed' => 'unpublished', 'created' => 'unpublished',
                          'completed' => 'concluded', 'deleted' => 'deleted',
                          'available' => 'active'}

      generate_and_run_report headers do |csv|
        courses.find_each do |c|
          row = []
          row << c.id unless @sis_format
          row << c.sis_source_id
          row << c.integration_id
          row << c.course_code
          row << c.name
          row << c.account_id unless @sis_format
          row << c.account.try(:sis_source_id)
          row << c.enrollment_term_id unless @sis_format
          row << c.enrollment_term.try(:sis_source_id)
          # for sis import format 'claimed', 'created', and 'available' are all considered active
          if @sis_format
            if c.workflow_state == 'deleted' || c.workflow_state == 'completed'
              row << c.workflow_state
            else
              row << 'active'
            end
          else
            row << course_state_sub[c.workflow_state]
          end
          if c.restrict_enrollments_to_course_dates
            row << default_timezone_format(c.start_at)
            row << default_timezone_format(c.conclude_at)
          else
            row << nil
            row << nil
          end
          row << c.course_format
          row << c.sis_batch_id? unless @sis_format
          csv << row
        end
      end
    end

    def sections
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['section_id', 'course_id', 'integration_id', 'name', 'status',
                   'start_date', 'end_date']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_section_id', 'canvas_section_id')
        headers << I18n.t('#account_reports.report_header_section__id', 'section_id')
        headers << I18n.t('#account_reports.report_header_canvas_course_id', 'canvas_course_id')
        headers << I18n.t('#account_reports.report_header_course__id', 'course_id')
        headers << I18n.t('#account_reports.report_header_integration_id', 'integration_id')
        headers << I18n.t('#account_reports.report_header_name', 'name')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('#account_reports.report_header_start__date', 'start_date')
        headers << I18n.t('#account_reports.report_header_end__date', 'end_date')
        headers << I18n.t('#account_reports.report_header_canvas_account_id', 'canvas_account_id')
        headers << I18n.t('#account_reports.report_header_account_id', 'account_id')
        headers << I18n.t('created_by_sis')
      end
      sections = root_account.course_sections.
        select("course_sections.*, nxc.sis_source_id AS non_x_course_sis_id,
                rc.sis_source_id AS course_sis_id, nxc.id AS non_x_course_id,
                ra.id AS r_account_id, ra.sis_source_id AS r_account_sis_id,
                nxc.account_id AS nx_account_id, nxa.sis_source_id AS nx_account_sis_id").
        joins("INNER JOIN #{Course.quoted_table_name} AS rc ON course_sections.course_id = rc.id
               INNER JOIN #{Account.quoted_table_name} AS ra ON rc.account_id = ra.id
               LEFT OUTER JOIN #{Course.quoted_table_name} AS nxc ON course_sections.nonxlist_course_id = nxc.id
               LEFT OUTER JOIN #{Account.quoted_table_name} AS nxa ON nxc.account_id = nxa.id")

      if @include_deleted
        sections.where!("course_sections.workflow_state<>'deleted'
                           OR
                           (course_sections.sis_source_id IS NOT NULL
                            AND (nxc.sis_source_id IS NOT NULL
                                 OR rc.sis_source_id IS NOT NULL))")
      else
        sections.where!("course_sections.workflow_state<>'deleted'
                           AND (nxc.workflow_state<>'deleted'
                                OR rc.workflow_state<>'deleted')")
      end

      if @sis_format
        sections = sections.where("course_sections.sis_source_id IS NOT NULL
                                     AND (nxc.sis_source_id IS NOT NULL
                                     OR rc.sis_source_id IS NOT NULL)")
      end

      sections = sections.where.not(course_sections: {sis_batch_id: nil}) if @created_by_sis
      sections = add_course_sub_account_scope(sections, 'rc')
      sections = add_term_scope(sections, 'rc')

      generate_and_run_report headers do |csv|
        sections.find_each do |s|
          row = []
          row << s.id unless @sis_format
          row << s.sis_source_id
          if s.nonxlist_course_id.nil?
            row << s.course_id unless @sis_format
            row << s.course_sis_id
          else
            row << s.non_x_course_id unless @sis_format
            row << s.non_x_course_sis_id
          end
          row << s.integration_id
          row << s.name
          row << s.workflow_state
          if s.restrict_enrollments_to_section_dates
            row << default_timezone_format(s.start_at)
            row << default_timezone_format(s.end_at)
          else
            row << nil
            row << nil
          end
          unless @sis_format
            if s.nonxlist_course_id == nil
              row << s.r_account_id
              row << s.r_account_sis_id
            else
              row << s.nx_account_id
              row << s.nx_account_sis_id
            end
            row << s.sis_batch_id?
          end
          csv << row
        end
      end
    end

    def enrollments
      include_other_roots = root_account.trust_exists?
      headers = enrollment_headers(include_other_roots)
      enrol = enrollment_query

      enrol = enrollment_query_options(enrol)

      enrollments_to_csv(enrol, headers, include_other_roots)
    end

    def enrollments_to_csv(enrol, headers, include_other_roots)
      generate_and_run_report headers do |csv|
        # the "start" parameter is purely to
        # force activerecord to use LIMIT/OFFSET
        # rather than a cursor for this iteration
        # because it often is big enough that the slave
        # kills it mid-run (http://www.postgresql.org/docs/9.0/static/hot-standby.html)
        enrol.preload(:root_account, :sis_pseudonym).find_in_batches(start: 0) do |batch|
          users = batch.map {|e| User.new(id: e.user_id)}.compact
          users += batch.map {|e| User.new(id: e.associated_user_id) unless e.associated_user_id.nil?}.compact
          users.uniq!
          users_by_id = users.index_by(&:id)
          pseudonyms = load_cross_shard_logins(users, include_deleted: @include_deleted)

          batch.each do |e|
            p = loaded_pseudonym(pseudonyms,
                                 users_by_id[e.user_id],
                                 include_deleted: @include_deleted,
                                 enrollment: e)
            next unless p
            p2 = nil
            row = enrollment_row(e, include_other_roots, p, p2, pseudonyms, users_by_id)
            csv << row
          end
        end
      end
    end

    def enrollment_row(e, include_other_roots, p, p2, pseudonyms, users_by_id)
      row = []
      row << e.course_id unless @sis_format
      row << e.course_sis_id
      row << e.user_id unless @sis_format
      row << p.sis_user_id
      row << e.sis_role
      row << e.role_id
      row << e.course_section_id unless @sis_format
      row << e.course_section_sis_id
      row << e.enroll_state
      row << e.associated_user_id unless @sis_format
      if !e.associated_user_id.nil?
        p2 = loaded_pseudonym(pseudonyms,
                              users_by_id[e.associated_user_id],
                              include_deleted: @include_deleted)
      end
      row << p2&.sis_user_id
      row << e.sis_batch_id? unless @sis_format
      row << e.type unless @sis_format
      row << e.limit_privileges_to_course_section
      row << e.id unless @sis_format
      row << HostUrl.context_host(p.account) if include_other_roots
      row
    end

    def enrollment_query_options(enrol)
      if @include_deleted
        enrol.where!("enrollments.workflow_state<>'deleted' OR enrollments.sis_batch_id IS NOT NULL")
      else
        enrol.where!("enrollments.workflow_state<>'deleted' AND enrollments.workflow_state<>'completed'")
      end

      if @sis_format
        enrol = enrol.where("enrollments.workflow_state NOT IN ('rejected', 'invited', 'creation_pending')
                               AND (courses.sis_source_id IS NOT NULL OR cs.sis_source_id IS NOT NULL)")
      end
      enrol
    end

    def enrollment_query
      enrol = root_account.enrollments.
        select("enrollments.*, courses.sis_source_id AS course_sis_id,
                cs.sis_source_id AS course_section_sis_id,
                CASE WHEN cs.workflow_state = 'deleted' THEN 'deleted'
                     WHEN courses.workflow_state = 'deleted' THEN 'deleted'
                     WHEN enrollments.workflow_state = 'invited' THEN 'invited'
                     WHEN enrollments.workflow_state = 'creation_pending' THEN 'invited'
                     WHEN enrollments.workflow_state = 'active' THEN 'active'
                     WHEN enrollments.workflow_state = 'completed' THEN 'concluded'
                     WHEN enrollments.workflow_state = 'inactive' THEN 'inactive'
                     WHEN enrollments.workflow_state = 'deleted' THEN 'deleted'
                     WHEN enrollments.workflow_state = 'rejected' THEN 'rejected' END AS enroll_state").
        joins("INNER JOIN #{CourseSection.quoted_table_name} cs ON cs.id = enrollments.course_section_id
               INNER JOIN #{Course.quoted_table_name} ON courses.id = cs.course_id").
        where("enrollments.type <> 'StudentViewEnrollment'")
      enrol = enrol.where.not(enrollments: {sis_batch_id: nil}) if @created_by_sis
      enrol = add_course_sub_account_scope(enrol)
      enrol = add_term_scope(enrol)
    end

    def enrollment_headers(include_other_roots)
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['course_id', 'user_id', 'role', 'role_id', 'section_id',
                   'status', 'associated_user_id', 'limit_section_privileges']
        headers << 'root_account' if include_other_roots
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_course_id', 'canvas_course_id')
        headers << I18n.t('#account_reports.report_header_course__id', 'course_id')
        headers << I18n.t('#account_reports.report_header_canvas_user_id', 'canvas_user_id')
        headers << I18n.t('#account_reports.report_header_user__id', 'user_id')
        headers << I18n.t('#account_reports.report_header_role', 'role')
        headers << I18n.t('#account_reports.report_header_role_id', 'role_id')
        headers << I18n.t('#account_reports.report_header_canvas_section_id', 'canvas_section_id')
        headers << I18n.t('#account_reports.report_header_section__id', 'section_id')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('#account_reports.report_header_canvas_associated_user_id', 'canvas_associated_user_id')
        headers << I18n.t('#account_reports.report_header_associated_user_id', 'associated_user_id')
        headers << I18n.t('created_by_sis')
        headers << I18n.t('base_role_type')
        headers << I18n.t('limit_section_privileges')
        headers << I18n.t('canvas_enrollment_id')
        headers << I18n.t('root_account') if include_other_roots
      end
      headers
    end

    def groups
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['group_id', 'group_category_id', 'account_id', 'course_id', 'name', 'status']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_group_id', 'canvas_group_id')
        headers << I18n.t('#account_reports.report_header_group_id', 'group_id')
        headers << I18n.t('canvas_group_category_id')
        headers << I18n.t('group_category_id')
        headers << I18n.t('#account_reports.report_header_canvas_account_id', 'canvas_account_id')
        headers << I18n.t('#account_reports.report_header_account_id', 'account_id')
        headers << I18n.t('canvas_course_id')
        headers << I18n.t('course_id')
        headers << I18n.t('name')
        headers << I18n.t('status')
        headers << I18n.t('created_by_sis')
        headers << I18n.t('context_id')
        headers << I18n.t('context_type')
        headers << I18n.t('group_category_id')
        headers << I18n.t('max_membership')
      end

      groups = root_account.all_groups.
        select("groups.*, accounts.sis_source_id AS account_sis_id,
                courses.sis_source_id AS course_sis_id,
                group_categories.sis_source_id AS gc_sis_id").
        joins("INNER JOIN #{Account.quoted_table_name} ON accounts.id = groups.account_id
               LEFT JOIN #{Course.quoted_table_name} ON courses.id = groups.context_id AND context_type='Course'
               LEFT JOIN #{GroupCategory.quoted_table_name} ON groups.group_category_id=group_categories.id")

      groups = groups.where.not(groups: {sis_source_id: nil}) if @sis_format
      groups = groups.where.not(groups: {sis_batch_id: nil}) if @created_by_sis

      if @include_deleted
        groups.where!("groups.workflow_state<>'deleted' OR groups.sis_source_id IS NOT NULL")
      else
        groups.where!("groups.workflow_state<>'deleted'")
      end

      if account != root_account
        groups.where!("(groups.context_type = 'Account'
                         AND (accounts.id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                           OR accounts.id = :account_id))
                       OR (groups.context_type = 'Course'
                         AND (courses.account_id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                           OR courses.account_id = :account_id))", { account_id: account.id })
      end

      generate_and_run_report headers do |csv|
        groups.find_each do |g|
          row = []
          row << g.id unless @sis_format
          row << g.sis_source_id
          row << g.group_category_id unless @sis_format
          row << g.gc_sis_id
          row << (g.context_type == 'Account' ? g.context_id : nil) unless @sis_format
          row << (g.context_type == 'Account' ? g.account_sis_id : nil)
          row << (g.context_type == 'Course' ? g.context_id : nil) unless @sis_format
          row << (g.context_type == 'Course' ? g.course_sis_id : nil)
          row << g.name
          row << g.workflow_state
          row << g.sis_batch_id? unless @sis_format
          row << g.context_id unless @sis_format
          row << g.context_type unless @sis_format
          row << g.group_category_id unless @sis_format
          row << g.max_membership unless @sis_format
          csv << row
        end
      end
    end

    def group_categories
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['group_category_id', 'account_id', 'course_id', 'category_name', 'status']
      else
        headers = []
        headers << I18n.t('canvas_group_category_id')
        headers << I18n.t('group_category_id')
        headers << I18n.t('context_id')
        headers << I18n.t('context_type')
        headers << I18n.t('name')
        headers << I18n.t('role')
        headers << I18n.t('self_signup')
        headers << I18n.t('group_limit')
        headers << I18n.t('auto_leader')
        headers << I18n.t('status')
      end

      root_account.shard.activate do
        if account != root_account
          group_categories = GroupCategory.
            joins("LEFT JOIN #{Course.quoted_table_name} c ON c.id = group_categories.context_id
                   AND group_categories.context_type = 'Course'").
            joins("LEFT JOIN #{Account.quoted_table_name} a ON a.id = group_categories.context_id
                   AND group_categories.context_type = 'Account'").
            where("a.id IN (#{Account.sub_account_ids_recursive_sql(account.id)}) OR a.id=? OR EXISTS (?)",
                  account,
                  CourseAccountAssociation.where("course_id=c.id").where(account_id: account))
        else
          group_categories = root_account.all_group_categories.
            joins("LEFT JOIN #{Account.quoted_table_name} a ON a.id = group_categories.context_id
                     AND group_categories.context_type = 'Account'
                   LEFT JOIN #{Course.quoted_table_name} c ON c.id = group_categories.context_id
                     AND group_categories.context_type = 'Course'")
        end
        group_categories.where!('group_categories.deleted_at IS NULL') unless @include_deleted
        if @sis_format
          group_categories = group_categories.
            select("group_categories.*, a.sis_source_id AS account_sis_id, c.sis_source_id AS course_sis_id").
            where.not(sis_batch_id: nil)
        end

        generate_and_run_report headers do |csv|
          group_categories.order('group_categories.id ASC').find_each do |g|
            row = []
            row << g.id unless @sis_format
            row << g.sis_source_id
            row << ((g.context_type == 'Account') ? g.account_sis_id : nil) if @sis_format
            row << ((g.context_type == 'Course') ? g.course_sis_id : nil) if @sis_format
            row << g.context_id unless @sis_format
            row << g.context_type unless @sis_format
            row << g.name
            row << g.role unless @sis_format
            row << g.self_signup unless @sis_format
            row << g.group_limit unless @sis_format
            row << g.auto_leader unless @sis_format
            row << (g.deleted_at? ? 'deleted' : 'active')
            csv << row
          end
        end
      end
    end

    def group_membership
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['group_id', 'user_id', 'status']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_group_id', 'canvas_group_id')
        headers << I18n.t('#account_reports.report_header_group_id', 'group_id')
        headers << I18n.t('#account_reports.report_header_canvas_user_id', 'canvas_user_id')
        headers << I18n.t('#account_reports.report_header_user__id', 'user_id')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('created_by_sis')
      end

      gm = root_account.all_groups.
        select("group_id, groups.sis_source_id, group_memberships.user_id,
                  group_memberships.workflow_state, group_memberships.sis_batch_id").
        joins("INNER JOIN #{GroupMembership.quoted_table_name} ON groups.id = group_memberships.group_id").
        where("NOT EXISTS (SELECT user_id
                           FROM #{Enrollment.quoted_table_name} e
                           WHERE e.type = 'StudentViewEnrollment'
                           AND e.user_id = group_memberships.user_id)")

      gm = gm.where.not(group_memberships: {sis_batch_id: nil}) if @sis_format || @created_by_sis

      if @include_deleted
        gm.where!("(groups.workflow_state<>'deleted'
                     AND group_memberships.workflow_state<>'deleted')
                     OR
                     (group_memberships.sis_batch_id IS NOT NULL)")
      else
        gm.where!("groups.workflow_state<>'deleted' AND group_memberships.workflow_state<>'deleted'")
      end

      if account != root_account
        gm = gm.joins("INNER JOIN #{Account.quoted_table_name} ON accounts.id = groups.account_id
                       LEFT JOIN #{Course.quoted_table_name} ON groups.context_type = 'Course' AND groups.context_id = courses.id")
        gm.where!("(groups.context_type = 'Account'
                         AND (accounts.id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                           OR accounts.id = :account_id))
                       OR (groups.context_type = 'Course'
                         AND (courses.account_id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                           OR courses.account_id = :account_id))", { account_id: account.id })
      end

      generate_and_run_report headers do |csv|
        gm.find_in_batches do |batch|
          users = batch.map {|au| User.new(id: au.user_id) }.compact.uniq
          users_by_id = users.index_by(&:id)
          sis_ids = load_cross_shard_logins(users, include_deleted: @include_deleted)

          batch.each do |m|
            row = []
            row << m.group_id unless @sis_format
            row << m.sis_source_id
            row << m.user_id unless @sis_format
            p = loaded_pseudonym(sis_ids,
                                 users_by_id[m.user_id],
                                 include_deleted: @include_deleted)
            next unless p
            row << p.sis_user_id
            row << m.workflow_state
            row << m.sis_batch_id? unless @sis_format
            csv << row
          end
        end
      end
    end

    def xlist
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['xlist_course_id', 'section_id', 'status']
      else
        headers = []
        headers << I18n.t('#account_reports.report_header_canvas_xlist_course_id', 'canvas_xlist_course_id')
        headers << I18n.t('#account_reports.report_header_xlist_course_id', 'xlist_course_id')
        headers << I18n.t('#account_reports.report_header_canvas_section_id', 'canvas_section_id')
        headers << I18n.t('#account_reports.report_header_section__id', 'section_id')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('#account_reports.report_header_canvas_nonxlist_course_id', 'canvas_nonxlist_course_id')
        headers << I18n.t('#account_reports.report_header_nonxlist_course_id', 'nonxlist_course_id')
      end
      @domain_root_account = root_account
      xl = root_account.course_sections.
        select("course_sections.*, courses.sis_source_id AS course_sis_id,
                nxc.sis_source_id AS nxc_sis_id").
        joins("INNER JOIN #{Course.quoted_table_name} ON course_sections.course_id = courses.id
               INNER JOIN #{Course.quoted_table_name} nxc ON course_sections.nonxlist_course_id = nxc.id").
        where("course_sections.nonxlist_course_id IS NOT NULL")

      xl = xl.where.not(course_sections: {sis_batch_id: nil}) if @created_by_sis
      xl = xl.where.not(courses: {sis_source_id: nil}, course_sections: {sis_source_id: nil}) if @sis_format

      if @include_deleted
        xl.where!("(courses.workflow_state<>'deleted'
                      AND course_sections.workflow_state<>'deleted')
                      OR
                      (courses.sis_source_id IS NOT NULL
                      AND course_sections.sis_source_id IS NOT NULL)")
      else
        xl.where!("courses.workflow_state<>'deleted'
                     AND courses.workflow_state<>'completed'
                     AND course_sections.workflow_state<>'deleted'")
      end

      xl = add_course_sub_account_scope(xl)
      xl = add_term_scope(xl)

      generate_and_run_report headers do |csv|
        xl.find_each do |x|
          row = []
          row << x.course_id unless @sis_format
          row << x.course_sis_id
          row << x.id unless @sis_format
          row << x.sis_source_id
          row << x.workflow_state
          row << x.nonxlist_course_id unless @sis_format
          row << x.nxc_sis_id unless @sis_format
          csv << row
        end
      end
    end

    def user_observers
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['observer_id', 'student_id', 'status']
      else
        headers = []
        headers << I18n.t('canvas_observer_id')
        headers << I18n.t('observer_id')
        headers << I18n.t('canvas_student_id')
        headers << I18n.t('student_id')
        headers << I18n.t('status')
        headers << I18n.t('created_by_sis')
      end

      observers = root_account.pseudonyms.
        select("pseudonyms.*,
                p2.sis_user_id AS observer_sis_id,
                p2.user_id AS observer_id,
                user_observers.workflow_state AS ob_state,
                user_observers.sis_batch_id AS o_batch_id").
        joins("INNER JOIN #{UserObservationLink.quoted_table_name} ON pseudonyms.user_id=user_observers.user_id
               INNER JOIN #{Pseudonym.quoted_table_name} AS p2 ON p2.user_id=user_observers.observer_id").
        where("p2.account_id=pseudonyms.account_id")

      observers = observers.where.not(user_observers: {sis_batch_id: nil}) if @created_by_sis || @sis_format
      observers = observers.active.where.not(user_observers: {workflow_state: 'deleted'}) unless @include_deleted

      generate_and_run_report headers do |csv|
        observers.find_each do |observer|
          row = []
          row << observer.observer_id unless @sis_format
          row << observer.observer_sis_id
          row << observer.user_id unless @sis_format
          row << observer.sis_user_id
          row << observer.ob_state
          row << observer.o_batch_id? unless @sis_format
          csv << row
        end
      end
    end

    def admins
      include_other_roots = root_account.trust_exists?
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = ['user_id','account_id','role_id','role','status']
        headers << 'root_account' if include_other_roots
      else
        headers = []
        headers << I18n.t('admin_user_name')
        headers << I18n.t('canvas_user_id')
        headers << I18n.t('user_id')
        headers << I18n.t('canvas_account_id')
        headers << I18n.t('account_id')
        headers << I18n.t('role_id')
        headers << I18n.t('role')
        headers << I18n.t('status')
        headers << I18n.t('created_by_sis')
        headers << I18n.t('root_account') if include_other_roots
      end

      root_account.shard.activate do
        admins = AccountUser.
          select("account_users.*,
                  a.sis_source_id AS account_sis_id,
                  r.name AS role_name,
                  u.name AS user_name").
          joins("INNER JOIN #{Account.quoted_table_name} a ON account_users.account_id=a.id
                 INNER JOIN #{User.quoted_table_name} u ON account_users.user_id=u.id
                 INNER JOIN #{Role.quoted_table_name} r ON account_users.role_id=r.id").
          where("account_users.account_id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                 OR account_users.account_id= :account_id", {account_id: account.id})

        admins = admins.where.not(account_users: {sis_batch_id: nil}) if @sis_format
        admins = admins.where.not(account_users: {workflow_state: 'deleted'}) unless @include_deleted

        generate_and_run_report headers do |csv|
          admins.find_in_batches do |batch|
            users = batch.map {|au| User.new(id: au.user_id) }.compact.uniq
            users_by_id = users.index_by(&:id)
            sis_ids = load_cross_shard_logins(users, include_deleted: @include_deleted)

            batch.each do |admin|
              row = []
              row << admin.user_name unless @sis_format
              row << admin.user_id unless @sis_format
              p = loaded_pseudonym(sis_ids,
                                   users_by_id[admin.user_id],
                                   include_deleted: @include_deleted)
              next unless p
              row << p.sis_user_id
              row << admin.account_id unless @sis_format
              row << admin.account_sis_id
              row << admin.role_id
              row << admin.role_name
              row << admin.workflow_state
              row << admin.sis_batch_id? unless @sis_format
              row << HostUrl.context_host(p.account) if include_other_roots
              csv << row
            end
          end
        end
      end
    end
  end
end
