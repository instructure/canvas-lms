module DifferentiableAssignment
  def differentiated_assignments_applies?
    return false if !context.feature_enabled?(:differentiated_assignments)

    if self.is_a?(Assignment) || Quizzes::Quiz.class_names.include?(self.class_name)
      self.only_visible_to_overrides
    elsif self.assignment
      self.assignment.only_visible_to_overrides
    else
      false
    end
  end

  def visible_to_user?(user, opts={})
    # slightly redundant conditional, but avoiding unnecessary lookups
    return true if opts[:differentiated_assignments] == false ||
                  (opts[:differentiated_assignments] == true && !self.only_visible_to_overrides) ||
                  !self.differentiated_assignments_applies? #checks if DA enabled on course and then only_visible_to_overrides

    # will add users if observer and only filter based on DA when necessary (not for teachers/some observers)
    visible_instances = DifferentiableAssignment.filter([self],user,self.context) do |_, user_ids|
      conditions = {user_id: user_ids}
      conditions[column_name] = self.id
      visibility_view.where(conditions)
    end
    visible_instances.any?
  end

  def visibility_view
    self.is_a?(Assignment) ? AssignmentStudentVisibility : Quizzes::QuizStudentVisibility
  end

  def column_name
    self.is_a?(Assignment) ? :assignment_id : :quiz_id
  end

  # will not filter the collection for teachers, will for non-observer students
  # will filter for observers with observed students but not for observers without observed students
  def self.filter(collection, user, context, opts={}, &filter_block)
    return collection if !user || (opts[:is_teacher] != false && context.grants_any_right?(user, :manage_content, :read_as_admin, :manage_grades, :manage_assignments))
    return filter_block.call(collection, [user.id]) unless context.user_has_been_observer?(user)

    observed_student_ids = opts[:observed_student_ids] || ObserverEnrollment.observed_student_ids(context, user)
    user_ids = [user.id].concat(observed_student_ids)
    # if observer is following no students, do not filter based on differentiated assignments
    observed_student_ids.any? ? filter_block.call(collection, user_ids) : collection
  end
end