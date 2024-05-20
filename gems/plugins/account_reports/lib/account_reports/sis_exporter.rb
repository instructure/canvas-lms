# frozen_string_literal: true

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

module AccountReports
  class SisExporter
    include ReportHelper
    include Pronouns

    SIS_CSV_REPORTS = %w[users
                         accounts
                         terms
                         courses
                         sections
                         enrollments
                         groups
                         group_membership
                         group_categories
                         xlist
                         user_observers
                         admins].freeze

    def initialize(account_report, params = {})
      @account_report = account_report
      @reports = SIS_CSV_REPORTS & @account_report.parameters.select { |_k, v| value_to_boolean(v) }.keys
      @sis_format = params[:sis_format]
      @created_by_sis = @account_report.parameters["created_by_sis"]
      extra_text_term(@account_report)
      include_deleted_objects
      include_enrollment_filter
      include_enrollment_states
    end

    def csv
      files = +""
      @reports.each do |report_name|
        files << "#{report_name} "
      end
      add_extra_text(I18n.t(
                       "account_reports.sis_exporter.reports",
                       "Reports: %{files}",
                       files:
                     ))

      case @reports.length
      when 0
        send_report
      when 1
        csv = send(@reports.first)
        send_report(csv)
      else
        csvs = {}

        @reports.each do |report_name|
          csvs[report_name] = send(report_name)
        end
        send_report(csvs)
        csvs
      end
    end

    def users
      headers = user_headers
      users = user_query
      users = user_query_options(users)

      generate_and_run_report headers do |csv|
        users.find_in_batches do |batch|
          emails = emails_by_user_id(batch.map(&:user_id))

          batch.each do |u|
            csv << user_row(u, emails)
          end
        end
      end
    end

    def user_headers
      headers = []
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[user_id
                     integration_id
                     authentication_provider_id
                     login_id
                     password
                     first_name
                     last_name
                     full_name
                     sortable_name
                     short_name
                     email
                     status]
      else # provisioning_report
        headers << "canvas_user_id"
        headers << "user_id"
        headers << "integration_id"
        headers << "authentication_provider_id"
        headers << "login_id"
        headers << "first_name"
        headers << "last_name"
        headers << "full_name"
        headers << "sortable_name"
        headers << "short_name"
        headers << "email"
        headers << "status"
        headers << "created_by_sis"
      end
      headers << "pronouns" if should_add_pronouns?
      headers
    end

    def should_add_pronouns?
      return @should_add_pronouns if defined?(@should_add_pronouns)

      # if root_account.can_add_pronouns? is true, that means the account is using pronouns
      # if one root_account has pronouns enabled, but does not want to have them in the report, we can disable for the one account
      # if any return false, don't export
      @should_add_pronouns = ![root_account.can_add_pronouns?.to_s,
                               root_account.enable_sis_export_pronouns?.to_s].include?("false")
    end

    def user_query
      root_account.shard.activate do
        root_account.pseudonyms.except(:preload).joins(:user).select(
          "pseudonyms.id, pseudonyms.sis_user_id, pseudonyms.user_id, pseudonyms.sis_batch_id,
           pseudonyms.integration_id,pseudonyms.authentication_provider_id,pseudonyms.unique_id,
           pseudonyms.workflow_state, users.sortable_name,users.updated_at AS user_updated_at,
           users.name, users.short_name, users.pronouns AS db_pronouns"
        ).where("NOT EXISTS (SELECT user_id
                             FROM #{Enrollment.quoted_table_name} e
                             WHERE e.type = 'StudentViewEnrollment'
                             AND e.user_id = pseudonyms.user_id)")
      end
    end

    def user_query_options(users)
      users = users.where.not(sis_user_id: nil) if @sis_format
      users = users.where.not(pseudonyms: { sis_batch_id: nil }) if @created_by_sis

      if @include_deleted
        users.where!("pseudonyms.workflow_state<>'deleted' OR pseudonyms.sis_user_id IS NOT NULL")
      else
        users.where!("pseudonyms.workflow_state<>'deleted'")
      end

      add_user_sub_account_scope(users)
    end

    def user_row(user, emails)
      row = []
      row << user.user_id unless @sis_format
      row << user.sis_user_id
      row << user.integration_id
      row << user.authentication_provider_id
      row << user.unique_id
      row << nil if @sis_format
      name_parts = User.name_parts(user.sortable_name, likely_already_surname_first: true)
      (row << name_parts[0]) || "" # first name
      (row << name_parts[1]) || "" # last name
      row << user.name
      row << user.sortable_name
      row << user.short_name
      row << emails[user.user_id].try(:path)
      row << user.workflow_state
      row << user.sis_batch_id? unless @sis_format
      row << translate_pronouns(user.db_pronouns) if should_add_pronouns?
      row
    end

    def accounts
      headers = account_headers
      accounts = account_query
      accounts = account_query_options(accounts)

      generate_and_run_report headers do |csv|
        accounts.find_each do |a|
          csv << account_row(a)
        end
      end
    end

    def account_headers
      headers = []
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[account_id parent_account_id name status]
      else
        headers << "canvas_account_id"
        headers << "account_id"
        headers << "canvas_parent_id"
        headers << "parent_account_id"
        headers << "name"
        headers << "status"
        headers << "created_by_sis"
      end
      headers
    end

    def account_query
      root_account
        .all_accounts
        .select("accounts.*, pa.id AS parent_id, pa.sis_source_id AS parent_sis_source_id")
        .joins("INNER JOIN #{Account.quoted_table_name} AS pa ON accounts.parent_account_id=pa.id")
    end

    def account_query_options(accounts)
      accounts = accounts.where.not(accounts: { sis_source_id: nil }) if @sis_format
      accounts = accounts.where.not(accounts: { sis_batch_id: nil }) if @created_by_sis

      if @include_deleted
        accounts.where!("accounts.workflow_state<>'deleted' OR accounts.sis_source_id IS NOT NULL")
      else
        accounts.where!("accounts.workflow_state<>'deleted'")
      end

      if account != root_account
        # this does not give the full tree pf sub accounts, just the direct children.
        accounts.where!(accounts: { parent_account_id: account })
      end
      accounts
    end

    def account_row(a)
      row = []
      row << a.id unless @sis_format
      row << a.sis_source_id
      row << a.parent_id unless @sis_format
      row << a.parent_sis_source_id
      row << a.name
      row << a.workflow_state
      row << a.sis_batch_id? unless @sis_format
      row
    end

    def terms
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[term_id name status start_date end_date]
      else
        headers = []
        headers << "canvas_term_id"
        headers << "term_id"
        headers << "name"
        headers << "status"
        headers << "start_date"
        headers << "end_date"
        headers << "created_by_sis"
      end
      terms = root_account.enrollment_terms
      terms = term_query_options(terms)

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

    def term_query_options(terms)
      terms = terms.where.not(sis_source_id: nil) if @sis_format
      terms = terms.where.not(enrollment_terms: { sis_batch_id: nil }) if @created_by_sis

      if @include_deleted
        terms.where("workflow_state<>'deleted' OR sis_source_id IS NOT NULL")
      else
        terms.where("workflow_state<>'deleted'")
      end
    end

    def courses
      headers = course_headers
      courses = course_query
      courses = course_query_options(courses)
      course_state_sub = { "claimed" => "unpublished",
                           "created" => "unpublished",
                           "completed" => "concluded",
                           "deleted" => "deleted",
                           "available" => "active" }

      generate_and_run_report headers do |csv|
        courses.find_in_batches do |batch|
          blueprint_map = {}
          root_account.shard.activate do
            sub_data = MasterCourses::ChildSubscription.active.where(child_course_id: batch).pluck(:child_course_id, :master_template_id).to_h
            template_data = MasterCourses::MasterTemplate.active.for_full_course.where(id: sub_data.values).pluck(:id, :course_id).to_h if sub_data.present?
            course_sis_data = Course.where(id: template_data.values).where.not(sis_source_id: nil).pluck(:id, :sis_source_id).to_h if template_data.present?

            sub_data.each do |child_course_id, template_id|
              blueprint_canvas_id = template_data[template_id]
              blueprint_sis_id = course_sis_data[blueprint_canvas_id]
              blueprint_map[child_course_id] = {
                id: blueprint_canvas_id,
                sis_id: blueprint_sis_id,
              }
            end
          end

          batch.each do |c|
            csv << course_row(c, course_state_sub, blueprint_map)
          end
        end
      end
    end

    def course_headers
      headers = []
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[course_id
                     integration_id
                     short_name
                     long_name
                     account_id
                     term_id
                     status
                     start_date
                     end_date
                     course_format
                     blueprint_course_id]
      else
        headers << "canvas_course_id"
        headers << "course_id"
        headers << "integration_id"
        headers << "short_name"
        headers << "long_name"
        headers << "canvas_account_id"
        headers << "account_id"
        headers << "canvas_term_id"
        headers << "term_id"
        headers << "status"
        headers << "start_date"
        headers << "end_date"
        headers << "course_format"
        headers << "canvas_blueprint_course_id"
        headers << "blueprint_course_id"
        headers << "created_by_sis"
      end
      headers
    end

    def course_query
      root_account.all_courses.preload(:account, :enrollment_term)
    end

    def course_query_options(courses)
      courses = courses.where.not(courses: { sis_source_id: nil }) if @sis_format
      courses = courses.where.not(courses: { sis_batch_id: nil }) if @created_by_sis

      if @include_deleted
        courses.where!("(courses.workflow_state='deleted' AND courses.updated_at > ?)
                          OR courses.workflow_state<>'deleted'
                          OR courses.sis_source_id IS NOT NULL",
                       120.days.ago)
      else
        courses.where!("courses.workflow_state<>'deleted' AND courses.workflow_state<>'completed'")
      end

      courses = add_course_sub_account_scope(courses)
      add_term_scope(courses)
    end

    def course_row(c, course_state_sub, blueprint_map)
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
      row << if @sis_format
               if c.workflow_state == "deleted" || c.workflow_state == "completed"
                 c.workflow_state
               else
                 "active"
               end
             else
               course_state_sub[c.workflow_state]
             end
      if c.restrict_enrollments_to_course_dates
        row << default_timezone_format(c.start_at)
        row << default_timezone_format(c.conclude_at)
      else
        row << nil
        row << nil
      end
      row << c.course_format
      row << blueprint_map[c.id]&.[](:id) unless @sis_format
      row << blueprint_map[c.id]&.[](:sis_id)
      row << c.sis_batch_id? unless @sis_format
      row
    end

    def sections
      headers = section_headers
      sections = section_query
      sections = section_query_options(sections)

      generate_and_run_report headers do |csv|
        sections.find_each do |s|
          csv << section_row(s)
        end
      end
    end

    def section_headers
      headers = []
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[section_id
                     course_id
                     integration_id
                     name
                     status
                     start_date
                     end_date]
      else
        headers << "canvas_section_id"
        headers << "section_id"
        headers << "canvas_course_id"
        headers << "course_id"
        headers << "integration_id"
        headers << "name"
        headers << "status"
        headers << "start_date"
        headers << "end_date"
        headers << "canvas_account_id"
        headers << "account_id"
        headers << "created_by_sis"
      end
      headers
    end

    def section_query
      root_account
        .course_sections
        .select("course_sections.*,
                rc.sis_source_id AS course_sis_id,
                ra.id AS r_account_id, ra.sis_source_id AS r_account_sis_id")
        .joins("INNER JOIN #{Course.quoted_table_name} AS rc ON course_sections.course_id = rc.id
               INNER JOIN #{Account.quoted_table_name} AS ra ON rc.account_id = ra.id")
    end

    def section_query_options(sections)
      if @include_deleted
        sections.where!("course_sections.workflow_state<>'deleted'
                           OR
                           (course_sections.sis_source_id IS NOT NULL
                            AND rc.sis_source_id IS NOT NULL)")
      else
        sections.where!("course_sections.workflow_state<>'deleted'
                           AND rc.workflow_state<>'deleted'")
      end

      if @sis_format
        sections = sections.where("course_sections.sis_source_id IS NOT NULL
                                     AND rc.sis_source_id IS NOT NULL")
      end

      sections = sections.where.not(course_sections: { sis_batch_id: nil }) if @created_by_sis
      sections = add_course_sub_account_scope(sections, "rc")
      add_term_scope(sections, "rc")
    end

    def section_row(s)
      row = []
      row << s.id unless @sis_format
      row << s.sis_source_id
      row << s.course_id unless @sis_format
      row << s.course_sis_id
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
        row << s.r_account_id
        row << s.r_account_sis_id
        row << s.sis_batch_id?
      end
      row
    end

    def enrollments
      @temp_enroll_feature_enabled = root_account.feature_enabled?(:temporary_enrollments)
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
        # because it often is big enough that the secondary
        # kills it mid-run (http://www.postgresql.org/docs/9.0/static/hot-standby.html)
        enrol.preload(:root_account, :sis_pseudonym, :role).find_in_batches(strategy: :id) do |batch|
          users = batch.filter_map { |e| User.new(id: e.user_id) }
          users += batch.filter_map { |e| User.new(id: e.associated_user_id) unless e.associated_user_id.nil? }
          if @temp_enroll_feature_enabled
            users += batch.filter_map do |e|
              User.new(id: e.temporary_enrollment_source_user_id) unless e.temporary_enrollment_source_user_id.nil?
            end
          end
          users.uniq!
          users_by_id = users.index_by(&:id)
          pseudonyms = preload_logins_for_users(users, include_deleted: @include_deleted)

          batch.each do |e|
            p = loaded_pseudonym(pseudonyms,
                                 users_by_id[e.user_id],
                                 include_deleted: @include_deleted,
                                 enrollment: e)
            next unless p

            row = enrollment_row(e, include_other_roots, p, pseudonyms, users_by_id)
            csv << row
          end
        end
      end
    end

    def enrollment_row(enrollment, include_other_roots, pseud, pseudonyms, users_by_id)
      associated_user_pseudonym = nil
      temporary_enrollment_provider_pseudonym = nil

      row = []
      row << enrollment.course_id unless @sis_format
      row << enrollment.course_sis_id
      row << enrollment.user_id unless @sis_format
      row << pseud.sis_user_id
      row << enrollment.sis_role
      row << enrollment.role_id
      row << enrollment.course_section_id unless @sis_format
      row << enrollment.course_section_sis_id
      row << enrollment.enroll_state
      row << enrollment.associated_user_id unless @sis_format
      unless enrollment.associated_user_id.nil?
        associated_user_pseudonym =
          loaded_pseudonym(pseudonyms, users_by_id[enrollment.associated_user_id], include_deleted: @include_deleted)
      end
      row << associated_user_pseudonym&.sis_user_id
      row << enrollment.sis_batch_id? unless @sis_format
      row << enrollment.type unless @sis_format
      row << enrollment.limit_privileges_to_course_section
      row << enrollment.id unless @sis_format
      row << enrollment.temporary_enrollment_source_user_id if @temp_enroll_feature_enabled && !@sis_format
      unless enrollment.temporary_enrollment_source_user_id.nil?
        temporary_enrollment_provider_pseudonym = loaded_pseudonym(pseudonyms, users_by_id[enrollment.temporary_enrollment_source_user_id], include_deleted: @include_deleted)
      end
      row << temporary_enrollment_provider_pseudonym&.sis_user_id if @temp_enroll_feature_enabled
      row << HostUrl.context_host(pseud.account) if include_other_roots
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

      if @enrollment_filter
        enrol = enrol.where(type: @enrollment_filter)
      end

      if @enrollment_states
        enrol = enrol.where(workflow_state: @enrollment_states)
      end
      enrol
    end

    def enrollment_query
      enrol = root_account.enrollments
                          .select("enrollments.*, courses.sis_source_id AS course_sis_id,
                cs.sis_source_id AS course_section_sis_id,
                CASE WHEN cs.workflow_state = 'deleted' THEN 'deleted'
                     WHEN courses.workflow_state = 'deleted' THEN 'deleted'
                     WHEN enrollments.workflow_state = 'invited' THEN 'invited'
                     WHEN enrollments.workflow_state = 'creation_pending' THEN 'invited'
                     WHEN enrollments.workflow_state = 'active' THEN 'active'
                     WHEN enrollments.workflow_state = 'completed' THEN 'concluded'
                     WHEN enrollments.workflow_state = 'inactive' THEN 'inactive'
                     WHEN enrollments.workflow_state = 'deleted' THEN 'deleted'
                     WHEN enrollments.workflow_state = 'rejected' THEN 'rejected' END AS enroll_state")
                          .joins("INNER JOIN #{CourseSection.quoted_table_name} cs ON cs.id = enrollments.course_section_id
               INNER JOIN #{Course.quoted_table_name} ON courses.id = cs.course_id")
                          .where("enrollments.type <> 'StudentViewEnrollment'")
      enrol = enrol.where.not(enrollments: { sis_batch_id: nil }) if @created_by_sis
      enrol = add_course_sub_account_scope(enrol)
      add_term_scope(enrol)
    end

    def enrollment_headers(include_other_roots)
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[course_id
                     user_id
                     role
                     role_id
                     section_id
                     status
                     associated_user_id
                     limit_section_privileges]
        headers << "temporary_enrollment_source_user_id" if @temp_enroll_feature_enabled
      else
        headers = []
        headers << "canvas_course_id"
        headers << "course_id"
        headers << "canvas_user_id"
        headers << "user_id"
        headers << "role"
        headers << "role_id"
        headers << "canvas_section_id"
        headers << "section_id"
        headers << "status"
        headers << "canvas_associated_user_id"
        headers << "associated_user_id"
        headers << "created_by_sis"
        headers << "base_role_type"
        headers << "limit_section_privileges"
        headers << "canvas_enrollment_id"
      end
      headers << "canvas_temporary_enrollment_source_user_id" if @temp_enroll_feature_enabled
      headers << "temporary_enrollment_source_user_id" if @temp_enroll_feature_enabled
      headers << "root_account" if include_other_roots
      headers
    end

    def groups
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[group_id group_category_id account_id course_id name status]
      else
        headers = []
        headers << "canvas_group_id"
        headers << "group_id"
        headers << "canvas_group_category_id"
        headers << "group_category_id"
        headers << "canvas_account_id"
        headers << "account_id"
        headers << "canvas_course_id"
        headers << "course_id"
        headers << "name"
        headers << "status"
        headers << "created_by_sis"
        headers << "context_id"
        headers << "context_type"
        headers << "max_membership"
      end

      groups = root_account.all_groups
                           .select("groups.*, accounts.sis_source_id AS account_sis_id,
                courses.sis_source_id AS course_sis_id,
                group_categories.sis_source_id AS gc_sis_id")
                           .joins("INNER JOIN #{Account.quoted_table_name} ON accounts.id = groups.account_id
               LEFT JOIN #{Course.quoted_table_name} ON courses.id = groups.context_id AND context_type='Course'
               LEFT JOIN #{GroupCategory.quoted_table_name} ON groups.group_category_id=group_categories.id")

      groups = group_query_options(groups)
      generate_and_run_report headers do |csv|
        groups.find_each do |g|
          row = []
          row << g.id unless @sis_format
          row << g.sis_source_id
          row << g.group_category_id unless @sis_format
          row << g.gc_sis_id
          row << ((g.context_type == "Account") ? g.context_id : nil) unless @sis_format
          row << ((g.context_type == "Account") ? g.account_sis_id : nil)
          row << ((g.context_type == "Course") ? g.context_id : nil) unless @sis_format
          row << ((g.context_type == "Course") ? g.course_sis_id : nil)
          row << g.name
          row << g.workflow_state
          row << g.sis_batch_id? unless @sis_format
          row << g.context_id unless @sis_format
          row << g.context_type unless @sis_format
          row << g.max_membership unless @sis_format
          csv << row
        end
      end
    end

    def group_query_options(groups)
      groups = groups.where.not(groups: { sis_source_id: nil }) if @sis_format
      groups = groups.where.not(groups: { sis_batch_id: nil }) if @created_by_sis
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
                           OR courses.account_id = :account_id))",
                      { account_id: account.id })
      end
      groups
    end

    def group_categories
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[group_category_id account_id course_id category_name status]
      else
        headers = []
        headers << "canvas_group_category_id"
        headers << "group_category_id"
        headers << "context_id"
        headers << "context_type"
        headers << "name"
        headers << "role"
        headers << "self_signup"
        headers << "group_limit"
        headers << "auto_leader"
        headers << "status"
      end

      root_account.shard.activate do
        group_categories = if account == root_account
                             root_account.all_group_categories
                                         .joins("LEFT JOIN #{Account.quoted_table_name} a ON a.id = group_categories.context_id
                     AND group_categories.context_type = 'Account'
                   LEFT JOIN #{Course.quoted_table_name} c ON c.id = group_categories.context_id
                     AND group_categories.context_type = 'Course'")
                           else
                             GroupCategory
                               .joins("LEFT JOIN #{Course.quoted_table_name} c ON c.id = group_categories.context_id
                   AND group_categories.context_type = 'Course'")
                               .joins("LEFT JOIN #{Account.quoted_table_name} a ON a.id = group_categories.context_id
                   AND group_categories.context_type = 'Account'")
                               .merge(
                                 Account.where("a.id IN (#{Account.sub_account_ids_recursive_sql(account.id)})")
                                 .or(Account.where(a: { id: account }))
                                 .or(Account.where(CourseAccountAssociation.where("course_id=c.id").where(account_id: account).arel.exists))
                               )
                           end
        group_categories = group_category_query_options(group_categories)

        generate_and_run_report headers do |csv|
          group_categories.order("group_categories.id ASC").find_each do |g|
            row = []
            row << g.id unless @sis_format
            row << g.sis_source_id
            row << ((g.context_type == "Account") ? g.account_sis_id : nil) if @sis_format
            row << ((g.context_type == "Course") ? g.course_sis_id : nil) if @sis_format
            row << g.context_id unless @sis_format
            row << g.context_type unless @sis_format
            row << g.name
            row << g.role unless @sis_format
            row << g.self_signup unless @sis_format
            row << g.group_limit unless @sis_format
            row << g.auto_leader unless @sis_format
            row << (g.deleted_at? ? "deleted" : "active")
            csv << row
          end
        end
      end
    end

    def group_category_query_options(group_categories)
      group_categories.where!("group_categories.deleted_at IS NULL") unless @include_deleted
      if @sis_format
        group_categories = group_categories
                           .select("group_categories.*, a.sis_source_id AS account_sis_id, c.sis_source_id AS course_sis_id")
                           .where.not(sis_batch_id: nil)
      end
      group_categories
    end

    def group_membership
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[group_id user_id status]
      else
        headers = []
        headers << "canvas_group_id"
        headers << "group_id"
        headers << "canvas_user_id"
        headers << "user_id"
        headers << "status"
        headers << "created_by_sis"
      end

      gm = root_account.all_groups
                       .select("group_id, groups.sis_source_id, group_memberships.user_id,
                  group_memberships.workflow_state, group_memberships.sis_batch_id")
                       .joins("INNER JOIN #{GroupMembership.quoted_table_name} ON groups.id = group_memberships.group_id")
                       .where("NOT EXISTS (SELECT user_id
                           FROM #{Enrollment.quoted_table_name} e
                           WHERE e.type = 'StudentViewEnrollment'
                           AND e.user_id = group_memberships.user_id)")

      gm = group_membership_query_options(gm)

      if account != root_account
        gm = gm.joins("INNER JOIN #{Account.quoted_table_name} ON accounts.id = groups.account_id
                       LEFT JOIN #{Course.quoted_table_name} ON groups.context_type = 'Course' AND groups.context_id = courses.id")
        gm.where!("(groups.context_type = 'Account'
                         AND (accounts.id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                           OR accounts.id = :account_id))
                       OR (groups.context_type = 'Course'
                         AND (courses.account_id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                           OR courses.account_id = :account_id))",
                  { account_id: account.id })
      end

      generate_and_run_report headers do |csv|
        gm.find_in_batches do |batch|
          users = batch.filter_map { |au| User.new(id: au.user_id) }.uniq
          users_by_id = users.index_by(&:id)
          sis_ids = preload_logins_for_users(users, include_deleted: @include_deleted)

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

    def group_membership_query_options(gm)
      gm = gm.where.not(group_memberships: { sis_batch_id: nil }) if @sis_format || @created_by_sis

      if @include_deleted
        gm.where!("(groups.workflow_state<>'deleted'
                     AND group_memberships.workflow_state<>'deleted')
                     OR
                     (group_memberships.sis_batch_id IS NOT NULL)")
      else
        gm.where!("groups.workflow_state<>'deleted' AND group_memberships.workflow_state<>'deleted'")
      end
      gm
    end

    def xlist
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[xlist_course_id section_id status]
      else
        headers = []
        headers << "canvas_xlist_course_id"
        headers << "xlist_course_id"
        headers << "canvas_section_id"
        headers << "section_id"
        headers << "status"
        headers << "canvas_nonxlist_course_id"
        headers << "nonxlist_course_id"
      end
      @domain_root_account = root_account
      xl = root_account.course_sections
                       .select("course_sections.*, courses.sis_source_id AS course_sis_id,
                nxc.sis_source_id AS nxc_sis_id")
                       .joins("INNER JOIN #{Course.quoted_table_name} ON course_sections.course_id = courses.id
               INNER JOIN #{Course.quoted_table_name} nxc ON course_sections.nonxlist_course_id = nxc.id")
                       .where.not(course_sections: { nonxlist_course_id: nil })

      xl = xlist_query_options(xl)
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

    def xlist_query_options(xl)
      xl = xl.where.not(course_sections: { sis_batch_id: nil }) if @created_by_sis
      xl = xl.where.not(courses: { sis_source_id: nil }).where.not(course_sections: { sis_source_id: nil }) if @sis_format

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
      add_term_scope(xl)
    end

    def user_observers
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[observer_id student_id status]
      else
        headers = []
        headers << "canvas_observer_id"
        headers << "observer_id"
        headers << "canvas_student_id"
        headers << "student_id"
        headers << "status"
        headers << "created_by_sis"
      end

      observers = root_account.pseudonyms
                              .select("pseudonyms.*,
                p2.sis_user_id AS observer_sis_id,
                p2.user_id AS observer_id,
                user_observers.workflow_state AS ob_state,
                user_observers.sis_batch_id AS o_batch_id")
                              .joins("INNER JOIN #{UserObservationLink.quoted_table_name} ON pseudonyms.user_id=user_observers.user_id
               INNER JOIN #{Pseudonym.quoted_table_name} AS p2 ON p2.user_id=user_observers.observer_id")
                              .where("p2.account_id=pseudonyms.account_id")
                              .where(user_observers: { root_account_id: root_account })

      observers = user_observer_query_options(observers)
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

    def user_observer_query_options(observers)
      observers = observers.where.not(user_observers: { sis_batch_id: nil }) if @created_by_sis || @sis_format
      observers = observers.active.where.not(user_observers: { workflow_state: "deleted" }) unless @include_deleted

      if account != root_account
        observers = observers
                    .where("EXISTS (SELECT user_id FROM #{UserAccountAssociation.quoted_table_name} uaa
                WHERE uaa.account_id = ? AND uaa.user_id=pseudonyms.user_id)",
                           account)
      end
      observers
    end

    def admins
      include_other_roots = root_account.trust_exists?
      if @sis_format
        # headers are not translated on sis_export to maintain import compatibility
        headers = %w[user_id account_id role_id role status]
      else
        headers = []
        headers << "admin_user_name"
        headers << "canvas_user_id"
        headers << "user_id"
        headers << "canvas_account_id"
        headers << "account_id"
        headers << "role_id"
        headers << "role"
        headers << "status"
        headers << "created_by_sis"
      end
      headers << "root_account" if include_other_roots

      root_account.shard.activate do
        admins = AccountUser
                 .select("account_users.*,
                  a.sis_source_id AS account_sis_id,
                  r.name AS role_name,
                  u.name AS user_name")
                 .joins("INNER JOIN #{Account.quoted_table_name} a ON account_users.account_id=a.id
                 INNER JOIN #{User.quoted_table_name} u ON account_users.user_id=u.id
                 INNER JOIN #{Role.quoted_table_name} r ON account_users.role_id=r.id")
                 .where("account_users.account_id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                 OR account_users.account_id= :account_id",
                        { account_id: account.id })

        admins = admin_query_options(admins)
        generate_and_run_report headers do |csv|
          admins.find_in_batches do |batch|
            users = batch.filter_map { |au| User.new(id: au.user_id) }.uniq
            users_by_id = users.index_by(&:id)
            sis_ids = preload_logins_for_users(users, include_deleted: @include_deleted)

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

    def admin_query_options(admins)
      admins = admins.where.not(account_users: { sis_batch_id: nil }) if @sis_format
      admins = admins.where.not(account_users: { workflow_state: "deleted" }) unless @include_deleted
      admins
    end
  end
end
