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

  def self.for_user_in_context(search_term, context, searcher, session=nil, options = {})
    search_term = search_term.to_s
    return User.none if search_term.strip.empty?
    SearchTermHelper.validate_search_term(search_term)

    @is_id = search_term =~ Api::ID_REGEX && Api::MAX_ID_RANGE.cover?(search_term.to_i)
    @include_login = context.grants_right?(searcher, session, :view_user_logins)
    @include_email = context.grants_right?(searcher, session, :read_email_addresses)
    @include_sis   = context.grants_any_right?(searcher, session, :read_sis, :manage_sis)

    context.shard.activate do
      users_scope = context_scope(context, searcher, options.slice(:enrollment_state, :include_inactive_enrollments))
      users_scope = users_scope.from("(#{conditions_statement(search_term, context.root_account, users_scope)}) AS users")
      users_scope = order_scope(users_scope, context, options.slice(:order, :sort))
      roles_scope(users_scope, context, options.slice(:enrollment_type, :enrollment_role,
        :enrollment_role_id, :exclude_groups))
    end
  end

  def self.conditions_statement(search_term, root_account, users_scope)
    pattern = like_string_for(search_term)
    params = {pattern: pattern, account: root_account, path_type: CommunicationChannel::TYPE_EMAIL, db_id: search_term}
    complex_sql(users_scope, params)
  end

  def self.like_string_for(search_term)
    pattern_type = (gist_search_enabled? ? :full : :right)
    wildcard_pattern(search_term, :type => pattern_type, :case_sensitive => false)
  end

  def self.scope_for(context, searcher, options={})
    users_scope = context_scope(context, searcher, options.slice(:enrollment_state, :include_inactive_enrollments))
    users_scope = order_scope(users_scope, context, options.slice(:order, :sort))
    roles_scope(users_scope, context, options.slice(:enrollment_role, :enrollment_role_id, :enrollment_type, :exclude_groups))
  end

  def self.context_scope(context, searcher, options={})
    enrollment_states = Array(options[:enrollment_state]) if options[:enrollment_state]
    include_prior_enrollments = !options[:enrollment_state].nil?
    include_inactive_enrollments = !!options[:include_inactive_enrollments]
    if context.is_a?(Account)
      User.of_account(context).active
    elsif context.is_a?(Course)
      context.users_visible_to(searcher, include_prior_enrollments,
        enrollment_state: enrollment_states, include_inactive: include_inactive_enrollments).distinct
    else
      context.users_visible_to(searcher, include_inactive: include_inactive_enrollments).distinct
    end
  end

  def self.order_scope(users_scope, context, options={})
    order = ' DESC NULLS LAST, id DESC' if options[:order] == 'desc'
    if options[:sort] == "last_login"
      users_scope.select("users.*").order(Arel.sql("last_login#{order}"))
    elsif options[:sort] == "username"
      users_scope.select("users.*").order_by_sortable_name(direction: options[:order] == 'desc' ? :descending : :ascending)
    elsif options[:sort] == "email"
      users_scope = users_scope.select("users.*, (SELECT path FROM #{CommunicationChannel.quoted_table_name}
                        WHERE communication_channels.user_id = users.id AND
                          communication_channels.path_type = 'email' AND
                          communication_channels.workflow_state <> 'retired'
                        ORDER BY communication_channels.position ASC
                        LIMIT 1)
                        AS email")
      users_scope.order(Arel.sql("email#{order}"))
    elsif options[:sort] == "sis_id"
      users_scope = users_scope.select(User.send(:sanitize_sql, [
        "users.*, (SELECT sis_user_id FROM #{Pseudonym.quoted_table_name}
        WHERE pseudonyms.user_id = users.id AND
          pseudonyms.workflow_state <> 'deleted' AND
          pseudonyms.account_id = ?
        LIMIT 1) AS sis_user_id",
        context.root_account_id || context.id
      ]))
      users_scope.order(Arel.sql("sis_user_id#{order}"))
    else
      users_scope.select("users.*").order_by_sortable_name
    end
  end

  def self.roles_scope(users_scope, context, options={})
    enrollment_roles = Array(options[:enrollment_role]) if options[:enrollment_role]
    enrollment_role_ids = Array(options[:enrollment_role_id]) if options[:enrollment_role_id]
    enrollment_types = Array(options[:enrollment_type]) if options[:enrollment_type]
    exclude_groups = Array(options[:exclude_groups]) if options[:exclude_groups]

    if enrollment_role_ids || enrollment_roles
      users_scope = users_scope.joins(:not_removed_enrollments).distinct if context.is_a?(Account)
      roles = if enrollment_role_ids
                enrollment_role_ids.map{|id| Role.get_role_by_id(id)}.compact
              else
                enrollment_roles.map do |name|
                  if context.is_a?(Account)
                    context.get_course_role_by_name(name)
                  else
                    context.account.get_course_role_by_name(name)
                  end
                end.compact
              end
      users_scope = users_scope.where("role_id IN (?)", roles.map(&:id))
    elsif enrollment_types
      enrollment_types = enrollment_types.map { |e| "#{e.camelize}Enrollment" }
      if enrollment_types.any?{ |et| !Enrollment.readable_types.keys.include?(et) }
        raise ArgumentError, 'Invalid Enrollment Type'
      end

      if context.is_a?(Account)
        # for example, one user can have multiple teacher enrollments, but
        # we only want one such a user record in results
        users_scope = users_scope.where("EXISTS (?)", Enrollment.where("enrollments.user_id=users.id").active.where(type: enrollment_types)).distinct
      else
        if context.is_a?(Group) && context.context_type == "Course"
          users_scope = users_scope.joins(:enrollments).where(:enrollments => {:course_id => context.context_id})
        end
        users_scope = users_scope.where(:enrollments => { :type => enrollment_types })
      end
    end

    if exclude_groups
      users_scope = users_scope.where(Group.not_in_group_sql_fragment(exclude_groups))
    end

    users_scope
  end

  private
  def self.complex_sql(users_scope, params)
    users_scope = users_scope.group(:id)
    queries = [name_sql(users_scope, params)]
    if complex_search_enabled?
      queries << id_sql(users_scope, params) if @is_id
      queries << login_sql(users_scope, params) if @include_login
      queries << sis_sql(users_scope, params) if @include_sis
      queries << email_sql(users_scope, params) if @include_email
    end
    queries.map(&:to_sql).join("\nUNION\n")
  end

  def self.id_sql(users_scope, params)
    users_scope.select("users.*, MAX(current_login_at) as last_login").
      joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
        AND pseudonyms.account_id = #{User.connection.quote(params[:account])}
        AND pseudonyms.workflow_state = 'active'").
      where(id: params[:db_id]).
      group(:id)
  end

  def self.name_sql(users_scope, params)
    users_scope.select("users.*, MAX(current_login_at) as last_login").
      joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
        AND pseudonyms.account_id = #{User.connection.quote(params[:account])}
        AND pseudonyms.workflow_state = 'active'").
      where(like_condition('users.name'), pattern: params[:pattern])
  end

  def self.login_sql(users_scope, params)
    users_scope.select("users.*, MAX(logins.current_login_at) as last_login").
      joins(:pseudonyms).
      joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
        AND logins.account_id = #{User.connection.quote(params[:account])}
        AND logins.workflow_state = 'active'").
      where(pseudonyms: {account_id: params[:account], workflow_state: 'active'}).
      where(like_condition('pseudonyms.unique_id'), pattern: params[:pattern])
  end

  def self.sis_sql(users_scope, params)
    users_scope.select("users.*, MAX(logins.current_login_at) as last_login").
      joins(:pseudonyms).
      joins("LEFT JOIN #{Pseudonym.quoted_table_name} AS logins ON logins.user_id = users.id
        AND logins.account_id = #{User.connection.quote(params[:account])}
        AND logins.workflow_state = 'active'").
      where(pseudonyms: {account_id: params[:account], workflow_state: 'active'}).
      where(like_condition('pseudonyms.sis_user_id'), pattern: params[:pattern])
  end

  def self.email_sql(users_scope, params)
    users_scope.select("users.*, MAX(current_login_at) as last_login").
      joins(:communication_channels).
      joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id = users.id
        AND pseudonyms.account_id = #{User.connection.quote(params[:account])}
        AND pseudonyms.workflow_state = 'active'").
      where(communication_channels: {workflow_state: ['active', 'unconfirmed'], path_type: params[:path_type]}).
      where(like_condition('communication_channels.path'), pattern: params[:pattern])
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
