module UserSearch

  def self.for_user_in_context(search_term, context, searcher, session=nil, options = {})
    search_term = search_term.to_s
    base_scope = scope_for(context, searcher, options.slice(:enrollment_type, :enrollment_role, :enrollment_role_id, :exclude_groups))
    if search_term.to_s =~ Api::ID_REGEX
      db_id = Shard.relative_id_for(search_term, Shard.current, Shard.current)
      user = base_scope.where(id: db_id).first
      if user
        return [user]
      elsif !SearchTermHelper.valid_search_term?(search_term)
        return []
      end
      # no user found by id, so lets go ahead with the regular search, maybe this person just has a ton of numbers in their name
    end

    SearchTermHelper.validate_search_term(search_term)

    unless context.grants_right?(searcher, session, :manage_students) ||
        context.grants_right?(searcher, session, :manage_admin_users)
      restrict_search = true
    end
    base_scope.where(conditions_statement(search_term, {:restrict_search => restrict_search}))
  end

  def self.conditions_statement(search_term, options={})
    pattern = like_string_for(search_term)
    conditions = []

    if complex_search_enabled? && !options[:restrict_search]
      conditions << complex_sql << pattern << pattern << CommunicationChannel::TYPE_EMAIL << pattern
    else
      conditions << like_condition('users.name') << pattern
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
    exclude_groups = Array(options[:exclude_groups]) if options[:exclude_groups]

    if context.is_a?(Account)
      users = User.of_account(context).active.select("users.id, users.name, users.short_name, users.sortable_name")
    else
      users = context.users_visible_to(searcher).uniq
    end
    users = users.order_by_sortable_name

    if enrollment_role_ids || enrollment_roles
      if enrollment_role_ids
        roles = enrollment_role_ids.map{|id| Role.get_role_by_id(id)}.compact
      else
        roles = enrollment_roles.map{|name| context.is_a?(Account) ? context.get_course_role_by_name(name) :
            context.account.get_course_role_by_name(name)}.compact
      end
      conditions_sql = "role_id IN (?)"
      # TODO: this can go away after we take out the enrollment role shim (after role_id has been populated)
      roles.each do |role|
        if role.built_in?
          conditions_sql += " OR (role_id IS NULL AND type = #{User.connection.quote(role.name)})"
        end
      end
      users = users.where(conditions_sql, roles.map(&:id))
    elsif enrollment_types
      enrollment_types = enrollment_types.map { |e| "#{e.capitalize}Enrollment" }
      if enrollment_types.any?{ |et| !Enrollment.readable_types.keys.include?(et) }
        raise ArgumentError, 'Invalid Enrollment Type'
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
    @_complex_sql ||= <<-SQL
      (EXISTS (SELECT 1 FROM pseudonyms 
         WHERE #{like_condition('pseudonyms.sis_user_id')} 
           AND pseudonyms.user_id = users.id 
           AND (pseudonyms.workflow_state IS NULL 
             OR pseudonyms.workflow_state != 'deleted'))
           OR (#{like_condition('users.name')}) 
             OR EXISTS (SELECT 1 FROM communication_channels 
               WHERE communication_channels.user_id = users.id 
                 AND (communication_channels.path_type = ? 
                 AND #{like_condition('communication_channels.path')})))
    SQL
  end

  def self.gist_search_enabled?
    Setting.get('user_search_with_gist', 'true') == 'true'
  end

  def self.complex_search_enabled?
    Setting.get('user_search_with_full_complexity', 'true') == 'true'
  end

  def self.like_condition(value)
    ActiveRecord::Base.like_condition(value, 'lower(?)')
  end

  def self.wildcard_pattern(value, options)
    ActiveRecord::Base.wildcard_pattern(value, options)
  end


end
