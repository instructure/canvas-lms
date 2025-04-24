# frozen_string_literal: true

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

module UserSearch
  class << self
    def for_user_in_context(search_term, context, searcher, session = nil, options = {})
      search_term = search_term.to_s
      return User.none if search_term.strip.empty?

      SearchTermHelper.validate_search_term(search_term)

      @is_id = search_term =~ Api::ID_REGEX && Api::MAX_ID_RANGE.cover?(search_term.to_i)
      @include_login       = context.grants_right?(searcher, session, :view_user_logins)
      @include_email       = context.grants_right?(searcher, session, :read_email_addresses)
      @include_sis         = context.grants_any_right?(searcher, session, :read_sis, :manage_sis)
      @include_integration = @include_sis
      @include_deleted_users = options[:include_deleted_users]

      context.shard.activate do
        users_scope = context_scope(context, searcher, options.slice(:enrollment_state, :include_inactive_enrollments))
        users_scope = users_scope.from("(#{conditions_statement(search_term, context.root_account, users_scope)}) AS users")
        users_scope = order_scope(users_scope, context, options.slice(:order, :sort))
        roles_scope(users_scope, context, options.slice(:enrollment_type,
                                                        :enrollment_role,
                                                        :enrollment_role_id,
                                                        :exclude_groups))
      end
    end

    def conditions_statement(search_term, root_account, users_scope)
      pattern = like_string_for(search_term)
      params = { pattern:, account: root_account, path_type: CommunicationChannel::TYPE_EMAIL, db_id: search_term }
      complex_sql(users_scope, params)
    end

    def like_string_for(search_term)
      wildcard_pattern(search_term, type: :full, case_sensitive: false)
    end

    def like_condition(value)
      ActiveRecord::Base.like_condition(value, "lower(:pattern)")
    end

    def scope_for(context, searcher, options = {})
      @include_deleted_users = options[:include_deleted_users]
      users_scope = context_scope(context, searcher, options.slice(:enrollment_state,
                                                                   :include_inactive_enrollments,
                                                                   :enrollment_role_id,
                                                                   :ui_invoked))
      users_scope = roles_scope(users_scope, context, options.slice(:enrollment_role,
                                                                    :enrollment_role_id,
                                                                    :enrollment_type,
                                                                    :exclude_groups,
                                                                    :ui_invoked,
                                                                    :temporary_enrollment_recipients,
                                                                    :temporary_enrollment_providers))
      order_scope(users_scope, context, options.slice(:order, :sort))
    end

    def context_scope(context, searcher, options = {})
      enrollment_states = Array(options[:enrollment_state]) if options[:enrollment_state]
      include_prior_enrollments = !options[:enrollment_state].nil?
      include_inactive_enrollments = !!options[:include_inactive_enrollments]
      case context
      when Account
        users = User.of_account(context).active
        users = users.union(context.pseudonym_users) if @include_deleted_users
        users
      when Course
        context.users_visible_to(searcher,
                                 include_prior_enrollments,
                                 enrollment_state: enrollment_states,
                                 include_inactive: include_inactive_enrollments).distinct
      else
        context.users_visible_to(searcher, include_inactive: include_inactive_enrollments).distinct
      end
    end

    def order_scope(users_scope, context, options = {})
      order = " DESC NULLS LAST, id DESC" if options[:order] == "desc"
      case options[:sort]
      when "last_login"
        users_scope.select("users.*").order(Arel.sql("last_login#{order}"))
      when "username"
        users_scope.select("users.*").order_by_sortable_name(direction: (options[:order] == "desc") ? :descending : :ascending)
      when "email"
        users_scope = users_scope.select("users.*, (SELECT path FROM #{CommunicationChannel.quoted_table_name}
                          WHERE communication_channels.user_id = users.id AND
                            communication_channels.path_type = 'email' AND
                            communication_channels.workflow_state <> 'retired'
                          ORDER BY communication_channels.position ASC
                          LIMIT 1)
                          AS email")
        users_scope.order(Arel.sql("email#{order}"))
      when "sis_id", "integration_id"
        column = (options[:sort] == "sis_id") ? "sis_user_id" : "integration_id"
        # sort pseudonyms based on pick_user_pseudonym in sis_pseudonym; grabs only the first pseudonym of each user
        # after sorting based on collation_key

        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*,
                                                    (SELECT #{column}
                                                      FROM #{Pseudonym.quoted_table_name}
                                                      WHERE pseudonyms.user_id = users.id
                                                        #{"AND pseudonyms.workflow_state <> 'deleted'" if @include_deleted_users}
                                                        AND pseudonyms.account_id = ?
                                                      ORDER BY workflow_state,
                                                              CASE WHEN pseudonyms.sis_user_id IS NOT NULL THEN 0 ELSE 1 END,
                                                              #{Pseudonym.best_unicode_collation_key("unique_id")},
                                                              position
                                                      LIMIT 1) AS #{column}",
                                                     context.try(:resolved_root_account_id) || context.root_account_id
                                                   ]))
        users_scope.order(Arel.sql("#{column} #{order}"))
      when "name"
        users_scope.select("users.*").order_by_name(direction: (options[:order] == "desc") ? :descending : :ascending)
      when "login_id"
        # sort pseudonyms based on SisPseudonym#pick_user_pseudonym
        # grab only the first pseudonym of each user after sorting based on collation_key
        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*,
                                                    (SELECT unique_id
                                                      FROM #{Pseudonym.quoted_table_name}
                                                      WHERE pseudonyms.user_id = users.id
                                                        #{"AND pseudonyms.workflow_state <> 'deleted'" unless @include_deleted_users}
                                                        AND pseudonyms.account_id = ?
                                                      ORDER BY workflow_state,
                                                              CASE WHEN pseudonyms.sis_user_id IS NOT NULL THEN 0 ELSE 1 END,
                                                              #{Pseudonym.best_unicode_collation_key("unique_id")},
                                                              position
                                                      LIMIT 1) AS login_id",
                                                     context.try(:resolved_root_account_id) || context.root_account_id
                                                   ]))
        users_scope.order(Arel.sql("login_id#{order}"))
      when "total_activity_time"
        raise_context_error("total_activity_time") unless context.is_a?(Course)

        # grab the max total_activity_time from all non-deleted user enrollments in the course
        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*,
                                                    (SELECT MAX(enrollments.total_activity_time)
                                                      FROM #{Enrollment.quoted_table_name}
                                                      WHERE enrollments.user_id = users.id
                                                        AND enrollments.workflow_state <> 'deleted'
                                                        AND enrollments.course_id = ?
                                                    ) AS total_activity_time",
                                                     context.id
                                                   ]))
        users_scope.order(Arel.sql("total_activity_time#{order}"))
      when "last_activity_at"
        raise_context_error("last_activity_at") unless context.is_a?(Course)

        # The order for last_activity_at is intentionally reversed because last activity is
        # a timestamp and we want the most recent activity to appear first in ascending order
        # Multiple users with the same last activity are ordered by their id in non-reversed order for consistency with other sorts
        # Observers are ignored because course roster does not display last activity for them
        reverse_order = if options[:order] == "desc"
                          " ASC NULLS LAST, id DESC"
                        else
                          " DESC NULLS LAST, id ASC"
                        end
        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*,
                                                    (SELECT last_activity_at
                                                      FROM #{Enrollment.quoted_table_name}
                                                      WHERE enrollments.user_id = users.id
                                                        AND enrollments.workflow_state <> 'deleted'
                                                        AND enrollments.type <> 'ObserverEnrollment'
                                                        AND enrollments.course_id = ?
                                                      ORDER BY last_activity_at
                                                      #{(options[:order] == "desc") ? "ASC" : "DESC"}
                                                      NULLS LAST
                                                      LIMIT 1) AS last_activity_at",
                                                     context.id
                                                   ]))
        users_scope.order(Arel.sql("last_activity_at#{reverse_order}"))
      when "section_name"
        raise_context_error("section_name") unless context.is_a?(Course)

        # ignore observers because course roster does not display section name for them
        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*,
                                                    (SELECT course_sections.name
                                                      FROM #{Enrollment.quoted_table_name}
                                                      LEFT JOIN #{CourseSection.quoted_table_name}
                                                      ON enrollments.course_section_id = course_sections.id
                                                      WHERE enrollments.user_id = users.id
                                                        AND enrollments.workflow_state <> 'deleted'
                                                        AND enrollments.type <> 'ObserverEnrollment'
                                                        AND enrollments.course_id = ?
                                                      ORDER BY course_sections.name
                                                      #{(options[:order] == "desc") ? "DESC" : "ASC"}
                                                      NULLS LAST
                                                      LIMIT 1) AS section_name",
                                                     context.id
                                                   ]))
        users_scope.order(Arel.sql("section_name#{order}"))
      when "role"
        raise_context_error("role") unless context.is_a?(Course)

        # custom ordering for roles - teacher ranks highest in ascending order
        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*,
                                                    (SELECT
                                                        CASE
                                                          WHEN type = 'TeacherEnrollment' THEN 0
                                                          WHEN type = 'TaEnrollment' THEN 1
                                                          WHEN type = 'StudentEnrollment' THEN 2
                                                          WHEN type = 'ObserverEnrollment' THEN 3
                                                          WHEN type = 'DesignerEnrollment' THEN 4
                                                        ELSE
                                                          NULL
                                                        END as role
                                                      FROM #{Enrollment.quoted_table_name}
                                                      WHERE enrollments.user_id = users.id
                                                        AND enrollments.workflow_state <> 'deleted'
                                                        AND enrollments.course_id = ?
                                                      ORDER BY role
                                                      #{(options[:order] == "desc") ? "DESC" : "ASC"}
                                                      NULLS LAST
                                                      LIMIT 1) AS role",
                                                     context.id
                                                   ]))
        users_scope.order(Arel.sql("role#{order}"))
      when "id"
        users_scope.order(id: (options[:order] == "desc") ? :desc : :asc)
      else
        users_scope.select("users.*").order_by_sortable_name
      end
    end

    def roles_scope(users_scope, context, options = {})
      enrollment_roles = Array(options[:enrollment_role]) if options[:enrollment_role]
      enrollment_role_ids = Array(options[:enrollment_role_id]) if options[:enrollment_role_id]
      enrollment_types = Array(options[:enrollment_type]) if options[:enrollment_type]
      exclude_groups = Array(options[:exclude_groups]) if options[:exclude_groups]

      if enrollment_role_ids || enrollment_roles
        role_ids =
          if enrollment_role_ids
            enrollment_role_ids.filter_map { |id| Role.get_role_by_id(id)&.id }
          else
            enrollment_roles.filter_map do |name|
              if context.is_a?(Account)
                context.get_course_role_by_name(name).id
              else
                context.account.get_course_role_by_name(name).id
              end
            end
          end
        users_scope =
          if context.is_a?(Account)
            users_scope.where(id: Enrollment.select(:user_id)
                       .where.not(enrollments: { workflow_state: %i[rejected inactive deleted] })
                       .where(role_id: role_ids))
          else
            users_scope.where(enrollments: { role_id: role_ids }).distinct
          end
      elsif enrollment_types
        enrollment_types = enrollment_types.map do |e|
          ce = e.camelize
          ce += "Enrollment" unless ce.end_with?("Enrollment")
          raise RequestError.new("Invalid enrollment type: #{e}", 400) unless Enrollment.readable_types.key?(ce)

          ce
        end

        if context.is_a?(Account)
          # for example, one user can have multiple teacher enrollments, but
          # we only want one such a user record in results
          users_scope = users_scope.where(Enrollment.where("enrollments.user_id=users.id").active.where(type: enrollment_types).arel.exists).distinct
        else
          if context.is_a?(Group) && context.context_type == "Course"
            users_scope = users_scope.joins(:enrollments).where(enrollments: { course_id: context.context_id })
          end
          users_scope = users_scope.where(enrollments: { type: enrollment_types })
        end
      end

      if exclude_groups
        users_scope = users_scope.where(Group.not_in_group_sql_fragment(exclude_groups))
      end

      if context.is_a?(Account) && !enrollment_types && context.root_account&.feature_enabled?(:temporary_enrollments)
        recipients = value_to_boolean(options[:temporary_enrollment_recipients])
        providers = value_to_boolean(options[:temporary_enrollment_providers])

        recipient_scope = Enrollment.active_or_pending_by_date.temporary_enrollment_recipients_for_provider(users_scope) if recipients
        provider_scope = Enrollment.active_or_pending_by_date.temporary_enrollments_for_recipient(users_scope) if providers

        users_scope =
          if recipients && providers
            users_scope.where(id: (recipient_scope.pluck(:user_id) + provider_scope.pluck(:temporary_enrollment_source_user_id)))
          elsif recipients
            users_scope.where(id: recipient_scope.select(:user_id))
          elsif providers
            users_scope.where(id: provider_scope.select(:temporary_enrollment_source_user_id))
          else
            users_scope
          end
      end

      users_scope
    end

    private

    def value_to_boolean(value)
      Canvas::Plugin.value_to_boolean(value)
    end

    def complex_sql(users_scope, params)
      users_scope = users_scope.group(:id)
      queries = [name_sql(users_scope, params)]
      queries << id_sql(users_scope, params) if @is_id
      queries << ids_sql(users_scope, params)
      queries << login_sql(users_scope, params) if @include_login
      queries << sis_sql(users_scope, params) if @include_sis
      queries << integration_sql(users_scope, params) if @include_integration
      queries << email_sql(users_scope, params) if @include_email
      queries.compact.map(&:to_sql).join("\nUNION\n")
    end

    def id_sql(users_scope, params)
      users_scope.select("users.*, MAX(pseudonyms.current_login_at) as last_login")
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{User.connection.quote(params[:account].id_for_database)}
          #{"AND pseudonyms.workflow_state = 'active'" unless @include_deleted_users}")
                 .where(id: params[:db_id])
                 .shard(Shard.current)
                 .group(:id)
    end

    def ids_sql(users_scope, params)
      ids = specific_ids(params)
      return nil unless ids.length.positive?

      users_scope.select("users.*, MAX(pseudonyms.current_login_at) as last_login")
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{User.connection.quote(params[:account].id_for_database)}
          #{"AND pseudonyms.workflow_state = 'active'" unless @include_deleted_users}")
                 .where(id: ids)
    end

    # Plugin extension point
    def specific_ids(_params)
      []
    end

    def name_sql(users_scope, params)
      users_scope.select("users.*, MAX(pseudonyms.current_login_at) as last_login")
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{User.connection.quote(params[:account].id_for_database)}
          #{"AND pseudonyms.workflow_state = 'active'" unless @include_deleted_users}")
                 .where(like_condition("users.name"), pattern: params[:pattern])
    end

    def login_sql(users_scope, params)
      scope = users_scope.select("users.*, MAX(logins.current_login_at) as last_login")
                         .joins(:pseudonyms)
                         .joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
                  AND logins.account_id = #{User.connection.quote(params[:account].id_for_database)}
                  #{"AND logins.workflow_state = 'active'" unless @include_deleted_users}")
                         .where(pseudonyms: { account_id: params[:account] })
                         .where(like_condition("pseudonyms.unique_id"), pattern: params[:pattern])
      scope = scope.where(pseudonyms: { workflow_state: "active" }) unless @include_deleted_users
      scope
    end

    def sis_sql(users_scope, params)
      scope = users_scope.select("users.*, MAX(logins.current_login_at) as last_login")
                         .joins(:pseudonyms)
                         .joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
                  AND logins.account_id = #{User.connection.quote(params[:account].id_for_database)}
                  #{"AND logins.workflow_state = 'active'" unless @include_deleted_users}")
                         .where(like_condition("pseudonyms.sis_user_id"), pattern: params[:pattern])
      scope = scope.where(pseudonyms: { account_id: params[:account], workflow_state: ["active", "suspended"] }) unless @include_deleted_users
      scope
    end

    def integration_sql(users_scope, params)
      scope = users_scope.select("users.*, MAX(logins.current_login_at) as last_login")
                         .joins(:pseudonyms)
                         .joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
                  AND logins.account_id = #{User.connection.quote(params[:account].id_for_database)}
                  #{"AND logins.workflow_state = 'active'" unless @include_deleted_users}")
                         .where(like_condition("pseudonyms.integration_id"), pattern: params[:pattern])
      scope = scope.where(pseudonyms: { account_id: params[:account], workflow_state: ["active", "suspended"] }) unless @include_deleted_users
      scope
    end

    def email_sql(users_scope, params)
      users_scope.select("users.*, MAX(pseudonyms.current_login_at) as last_login")
                 .joins(:communication_channels)
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{User.connection.quote(params[:account].id_for_database)}
          #{"AND pseudonyms.workflow_state = 'active'" unless @include_deleted_users}")
                 .where(communication_channels: { workflow_state: ["active", "unconfirmed"], path_type: params[:path_type] })
                 .where(like_condition("communication_channels.path"), pattern: params[:pattern])
    end

    def wildcard_pattern(value, **)
      ActiveRecord::Base.wildcard_pattern(value, **)
    end

    def raise_context_error(field)
      raise RequestError.new("Sorting by #{field} is only available within a course context", 400)
    end
  end

  class Bookmarker
    attr_accessor :order

    def initialize(order: nil)
      self.order = (order.to_s == "desc") ? :desc : :asc
    end

    def bookmark_for(user)
      user.id.to_s
    end

    def validate(bookmark)
      bookmark =~ /^\d+$/
    end

    def restrict_scope(scope, pager)
      if pager.current_bookmark
        id = pager.current_bookmark.to_i
        scope = scope.where("users.id #{comparison(pager.include_bookmark)} ?", id)
      end
      scope.order("users.id #{order}")
    end

    def comparison(include_bookmark)
      if include_bookmark
        (order == :desc) ? "<=" : ">="
      else
        (order == :desc) ? "<" : ">"
      end
    end
  end
end
