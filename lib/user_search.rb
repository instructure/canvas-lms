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

  def self.for_user_in_context(search_term, context, searcher, session=nil, options = {})
    search_term = search_term.to_s
    return User.none if search_term.strip.empty?
    SearchTermHelper.validate_search_term(search_term)

    @is_id = search_term =~ Api::ID_REGEX
    @include_login = context.grants_right?(searcher, session, :view_user_logins)
    @include_email = context.grants_right?(searcher, session, :read_email_addresses)
    @include_sis   = context.grants_any_right?(searcher, session, :read_sis, :manage_sis)

    context.shard.activate do
      base_scope = scope_for(context, searcher, options.slice(:enrollment_type, :enrollment_role,
        :enrollment_role_id, :exclude_groups, :enrollment_state, :include_inactive_enrollments, :sort, :order))

      # TODO: Need to optimize this as it's not using the base scope filter for the conditions statement query
      base_scope.where(conditions_statement(search_term, context.root_account))
    end
  end

  def self.complex_search?
    @include_login || @include_email || @include_sis || @is_id
  end

  def self.conditions_statement(search_term, root_account, options={})
    pattern = like_string_for(search_term)
    conditions = []

    if complex_search_enabled? && complex_search?
      # db_id is only used if the search_term.to_s =~ Api::ID_REGEX
      params = {pattern: pattern, account: root_account, path_type: CommunicationChannel::TYPE_EMAIL, db_id: search_term}
      conditions << complex_sql << params
    else
      conditions << like_condition('users.name') << {pattern: pattern}
    end

    conditions
  end

  def self.like_string_for(search_term)
    pattern_type = (gist_search_enabled? ? :full : :right)
    wildcard_pattern(search_term, :type => pattern_type, :case_sensitive => false)
  end

  def self.scope_for(context, searcher, options={})
    enrollment_roles = Array(options[:enrollment_role]) if options[:enrollment_role]
    enrollment_role_ids = Array(options[:enrollment_role_id]) if options[:enrollment_role_id]
    enrollment_types = Array(options[:enrollment_type]) if options[:enrollment_type]
    enrollment_states = Array(options[:enrollment_state]) if options[:enrollment_state]
    include_prior_enrollments = !options[:enrollment_state].nil?
    include_inactive_enrollments = !!options[:include_inactive_enrollments]
    exclude_groups = Array(options[:exclude_groups]) if options[:exclude_groups]

    users = if context.is_a?(Account)
              User.of_account(context).active
            elsif context.is_a?(Course)
              context.users_visible_to(searcher, include_prior_enrollments,
                enrollment_state: enrollment_states, include_inactive: include_inactive_enrollments).distinct
            else
              context.users_visible_to(searcher).distinct
            end

    users = if options[:sort] == "last_login"
              if options[:order] == 'desc'
                users.order(Arel.sql("MAX(current_login_at) DESC NULLS LAST, id DESC"))
              else
                users.order(Arel.sql("MAX(current_login_at), id"))
              end
            elsif options[:sort] == "username"
              if options[:order] == 'desc'
                users.order_by_sortable_name(direction: :descending)
              else
                users.order_by_sortable_name
              end
            elsif options[:sort] == "email"
              users = users.select("users.*, (SELECT path FROM #{CommunicationChannel.quoted_table_name}
                                WHERE communication_channels.user_id = users.id AND
                                  communication_channels.path_type = 'email' AND
                                  communication_channels.workflow_state <> 'retired'
                                ORDER BY communication_channels.position ASC
                                LIMIT 1)
                                AS email")
              if options[:order] == 'desc'
                users.order(Arel.sql("email DESC, id DESC"))
              else
                users.order(Arel.sql("email"))
              end
            elsif options[:sort] == "sis_id"
              users = users.select(User.send(:sanitize_sql, [
                                "users.*, (SELECT sis_user_id FROM #{Pseudonym.quoted_table_name}
                                WHERE pseudonyms.user_id = users.id AND
                                  pseudonyms.workflow_state <> 'deleted' AND
                                  pseudonyms.account_id = ?
                                LIMIT 1) AS sis_user_id",
                                context.root_account_id || context.id]))
              if options[:order] == 'desc'
                users.order(Arel.sql("sis_user_id DESC, id DESC"))
              else
                users.order(Arel.sql("sis_user_id"))
              end
            else
              users.order_by_sortable_name
            end

    if enrollment_role_ids || enrollment_roles
      users = users.joins(:not_removed_enrollments).distinct if context.is_a?(Account)
      roles = if enrollment_role_ids
                enrollment_role_ids.map{|id| Role.get_role_by_id(id)}.compact
              else
                enrollment_roles.map{|name| context.is_a?(Account) ? context.get_course_role_by_name(name) :
                  context.account.get_course_role_by_name(name)}.compact
              end
      users = users.where("role_id IN (?)", roles.map(&:id))
    elsif enrollment_types
      enrollment_types = enrollment_types.map { |e| "#{e.camelize}Enrollment" }
      if enrollment_types.any?{ |et| !Enrollment.readable_types.keys.include?(et) }
        raise ArgumentError, 'Invalid Enrollment Type'
      end
      if context.is_a?(Group) && context.context_type == "Course"
        users = users.joins(:enrollments).where(:enrollments => {:course_id => context.context_id})
      end
      users = users.where(:enrollments => { :type => enrollment_types })
    end

    if exclude_groups
      users = users.where(Group.not_in_group_sql_fragment(exclude_groups))
    end

    users
  end

  private

  def self.complex_sql
    id_queries = ["SELECT id FROM #{User.quoted_table_name} WHERE (#{like_condition('users.name')})"]

    if @include_login || @include_sis
      pseudonym_conditions = []
      pseudonym_conditions << like_condition('pseudonyms.unique_id') if @include_login
      pseudonym_conditions << like_condition('pseudonyms.sis_user_id') if @include_sis
      id_queries << <<-SQL
        SELECT user_id FROM #{Pseudonym.quoted_table_name}
          WHERE (#{pseudonym_conditions.join(' OR ')})
          AND pseudonyms.workflow_state='active'
          AND pseudonyms.account_id=:account
      SQL
    end

    if @is_id
      id_queries << "SELECT id FROM #{User.quoted_table_name} WHERE users.id IN (:db_id)"
    end

    if @include_email
      id_queries << <<-SQL
        SELECT communication_channels.user_id FROM #{CommunicationChannel.quoted_table_name}
          WHERE EXISTS (SELECT 1 FROM #{UserAccountAssociation.quoted_table_name} AS uaa
                        WHERE uaa.account_id= :account
                          AND uaa.user_id=communication_channels.user_id)
            AND communication_channels.path_type = :path_type
            AND #{like_condition('communication_channels.path')}
            AND communication_channels.workflow_state IN ('active', 'unconfirmed')
      SQL
    end

    "users.id IN (#{id_queries.join("\nUNION\n")})"
  end

  def self.gist_search_enabled?
    Setting.get('user_search_with_gist', 'true') == 'true'
  end

  def self.complex_search_enabled?
    Setting.get('user_search_with_full_complexity', 'true') == 'true'
  end

  def self.like_condition(value)
    ActiveRecord::Base.like_condition(value, 'lower(:pattern)')
  end

  def self.wildcard_pattern(value, options)
    ActiveRecord::Base.wildcard_pattern(value, options)
  end


end
