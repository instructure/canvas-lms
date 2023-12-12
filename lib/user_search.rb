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

      context.shard.activate do
        users_scope = context_scope(context, searcher, options.slice(:enrollment_state, :include_inactive_enrollments, :include_deleted_users))
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
      users_scope = context_scope(context, searcher, options.slice(:enrollment_state,
                                                                   :include_inactive_enrollments,
                                                                   :enrollment_role_id,
                                                                   :ui_invoked,
                                                                   :include_deleted_users))
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
        users = users.union(context.deleted_users) if options[:include_deleted_users]
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
        users_scope = users_scope.select(User.send(:sanitize_sql, [
                                                     "users.*, (SELECT #{column} FROM #{Pseudonym.quoted_table_name}
          WHERE pseudonyms.user_id = users.id AND
            pseudonyms.workflow_state <> 'deleted' AND
            pseudonyms.account_id = ?
          LIMIT 1) AS #{column}",
                                                     context.try(:resolved_root_account_id) || context.root_account_id
                                                   ]))
        users_scope.order(Arel.sql("#{column}#{order}"))
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
            enrollment_role_ids.filter_map { |id| Role.get_role_by_id(id).id }
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
          AND pseudonyms.workflow_state = 'active'")
                 .where(id: params[:db_id])
                 .group(:id)
    end

    def ids_sql(users_scope, params)
      ids = specific_ids(params)
      return nil unless ids.length.positive?

      users_scope.select("users.*, MAX(pseudonyms.current_login_at) as last_login")
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{User.connection.quote(params[:account].id_for_database)}
          AND pseudonyms.workflow_state = 'active'")
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
          AND pseudonyms.workflow_state = 'active'")
                 .where(like_condition("users.name"), pattern: params[:pattern])
    end

    def login_sql(users_scope, params)
      users_scope.select("users.*, MAX(logins.current_login_at) as last_login")
                 .joins(:pseudonyms)
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
          AND logins.account_id = #{User.connection.quote(params[:account].id_for_database)}
          AND logins.workflow_state = 'active'")
                 .where(pseudonyms: { account_id: params[:account], workflow_state: "active" })
                 .where(like_condition("pseudonyms.unique_id"), pattern: params[:pattern])
    end

    def sis_sql(users_scope, params)
      users_scope.select("users.*, MAX(logins.current_login_at) as last_login")
                 .joins(:pseudonyms)
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
          AND logins.account_id = #{User.connection.quote(params[:account].id_for_database)}
          AND logins.workflow_state = 'active'")
                 .where(pseudonyms: { account_id: params[:account], workflow_state: ["active", "suspended"] })
                 .where(like_condition("pseudonyms.sis_user_id"), pattern: params[:pattern])
    end

    def integration_sql(users_scope, params)
      users_scope.select("users.*, MAX(logins.current_login_at) as last_login")
                 .joins(:pseudonyms)
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
          AND logins.account_id = #{User.connection.quote(params[:account].id_for_database)}
          AND logins.workflow_state = 'active'")
                 .where(pseudonyms: { account_id: params[:account], workflow_state: ["active", "suspended"] })
                 .where(like_condition("pseudonyms.integration_id"), pattern: params[:pattern])
    end

    def email_sql(users_scope, params)
      users_scope.select("users.*, MAX(pseudonyms.current_login_at) as last_login")
                 .joins(:communication_channels)
                 .joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
          AND pseudonyms.account_id = #{User.connection.quote(params[:account].id_for_database)}
          AND pseudonyms.workflow_state = 'active'")
                 .where(communication_channels: { workflow_state: ["active", "unconfirmed"], path_type: params[:path_type] })
                 .where(like_condition("communication_channels.path"), pattern: params[:pattern])
    end

    def wildcard_pattern(value, **options)
      ActiveRecord::Base.wildcard_pattern(value, **options)
    end
  end
end
