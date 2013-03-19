module UserSearch

  def self.for_user_in_course(search_term, course, searcher, options = {})
    base_scope = scope_for(course, searcher, options.slice(:enrollment_type, :enrollment_role))
    if search_term.to_s =~ Api::ID_REGEX
      user = base_scope.find_by_id(search_term)
      return [user] if user
      # no user found by id, so lets go ahead with the regular search, maybe this person just has a ton of numbers in their name
    end

    base_scope.where(conditions_statement(search_term))
  end

  def self.conditions_statement(search_term)
    pattern = like_string_for(search_term)
    conditions = []

    if complex_search_enabled?
      conditions << complex_sql << pattern << pattern << CommunicationChannel::TYPE_EMAIL << pattern
    else
      conditions << like_condition('users.name') << pattern
    end

    conditions
  end

  def self.like_string_for(search_term)
    pattern_type = (gist_search_enabled? ? :full : :right)
    wildcard_pattern(search_term, :type => pattern_type)
  end

  def self.scope_for(course, searcher, options={})
    enrollment_role = Array(options[:enrollment_role]) if options[:enrollment_role]
    enrollment_type = Array(options[:enrollment_type]) if options[:enrollment_type]

    users = course.users_visible_to(searcher).uniq.order_by_sortable_name

    if enrollment_role
      users = users.where("COALESCE(enrollments.role_name, enrollments.type) IN (?) ", enrollment_role)
    elsif enrollment_type
      enrollment_type = enrollment_type.map { |e| "#{e.capitalize}Enrollment" }
      if enrollment_type.any?{ |et| !Enrollment::READABLE_TYPES.keys.include?(et) }
        raise ArgumentError, 'Invalid Enrollment Type'
      end
      users = users.where(:enrollments => { :type => enrollment_type })
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
    Setting.get_cached('user_search_with_gist', false) == 'true'
  end

  def self.complex_search_enabled?
    Setting.get_cached('user_search_with_full_complexity', false) == 'true'
  end

  def self.like_condition(value)
    ActiveRecord::Base.like_condition(value)
  end

  def self.wildcard_pattern(value, options)
    ActiveRecord::Base.wildcard_pattern(value, options)
  end


end
