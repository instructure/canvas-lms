module EnrollmentDateRestrictions
  def self.included(klass)
    klass.send :before_save, :check_for_date_restrictions
    klass.send :after_save, :schedule_date_restrictions_update
  end

  def check_for_date_restrictions
    @schedule_restrictions_update = restrict_dates? &&
      ((start_at && start_at_changed?) || (end_at && end_at_changed?))
    true
  end
  
  def restrict_dates?
    (self.is_a?(Course) && restrict_enrollments_to_course_dates) || 
    (self.is_a?(CourseSection) && restrict_enrollments_to_section_dates) ||
    # as of right now overrides at the enrollment level require
    # both start_at *and* end_at to be set.
    (self.is_a?(Enrollment) && start_at && end_at) ||
    (self.is_a?(EnrollmentTerm) && !ignore_term_date_restrictions) ||
    (self.is_a?(EnrollmentDatesOverride) && !enrollment_term.ignore_term_date_restrictions)
  end
  
  def schedule_date_restrictions_update
    if @schedule_restrictions_update
      strand = "enrollment_date_restriction:update_restricted_enrollments:#{self.asset_string}"
      if start_at && start_at > Time.now
        EnrollmentDateRestrictions.send_later_enqueue_args(:update_restricted_enrollments,
          { :run_at => start_at, :strand => strand }, self)
      end
      if end_at && end_at > Time.now
        EnrollmentDateRestrictions.send_later_enqueue_args(:update_restricted_enrollments,
          { :run_at => end_at, :strand => strand }, self)
      end
      EnrollmentDateRestrictions.send_later_enqueue_args(:update_restricted_enrollments,
        { :strand => strand }, self)
    end
  end
  
  def self.update_restricted_enrollments(context)
    start_at = context.start_at
    end_at = context.end_at
    all_enrollment_ids = []
    @course_lookups = []
    if context.is_a?(Course)
      if context.available? && context.restrict_enrollments_to_course_dates
        all_enrollment_ids = Enrollment.find(:all, :conditions => {:course_id => context.id}, :select => 'id').map(&:id)
      end
    elsif context.is_a?(CourseSection)
      if context.restrict_enrollments_to_section_dates
        all_enrollment_ids = Enrollment.find(:all, :conditions => {:course_section_id => context.id}, :select => 'id').map(&:id)
      end
    elsif context.is_a?(EnrollmentDatesOverride)
      term = context.enrollment_term
      start_at = nil if term.ignore_term_date_restrictions
      end_at = nil if term.ignore_term_date_restrictions
      all_enrollment_ids = Enrollment.find(:all, :joins => [:course], :conditions => ['enrollments.course_id = courses.id AND courses.enrollment_term_id = ? AND enrollments.type = ?', context.enrollment_term_id, context.enrollment_type], :select => 'enrollments.id').map(&:id)
      all_enrollment_ids += Enrollment.find(:all, :joins => [:course_section], :conditions => ['enrollments.course_section_id = course_sections.id AND course_sections.enrollment_term_id = ? AND enrollments.type = ?', context.enrollment_term_id, context.enrollment_type], :select => 'enrollments.id').map(&:id)
    elsif context.is_a?(Enrollment)
      all_enrollment_ids = [context.id]
    elsif context.is_a?(EnrollmentTerm)
      start_at = nil if context.ignore_term_date_restrictions
      end_at = nil if context.ignore_term_date_restrictions
      all_enrollment_ids = Enrollment.find(:all, :joins => [:course], :conditions => ['enrollments.course_id = courses.id AND courses.enrollment_term_id = ?', context.id], :select => 'enrollments.id').map(&:id)
      all_enrollment_ids += Enrollment.find(:all, :joins => [:course_section], :conditions => ['enrollments.course_section_id = course_sections.id AND course_sections.enrollment_term_id = ?', context.id], :select => 'enrollments.id').map(&:id)
    end
    
    return if all_enrollment_ids.empty?
    
    if (!start_at || start_at <= Time.now) && (!end_at || end_at >= Time.now)
      Enrollment.find_all_by_id_and_workflow_state(all_enrollment_ids, 'inactive').each do |enrollment|
        course = lookup_enrollment_course(enrollment)
        if course.enrollment_state_based_on_date(enrollment) == 'active'
          enrollment.activate
        end
      end
    elsif start_at && start_at >= Time.now
      Enrollment.find_all_by_id_and_workflow_state(all_enrollment_ids, ['active']).each do |enrollment|
        course = lookup_enrollment_course(enrollment)
        if course.enrollment_state_based_on_date(enrollment) == 'inactive'
          enrollment.deactivate
        end
      end
    elsif end_at && end_at <= Time.now
      Enrollment.find_all_by_id_and_workflow_state(all_enrollment_ids, ['active', 'invited']).each do |enrollment|
        course = lookup_enrollment_course(enrollment)
        if course.enrollment_state_based_on_date(enrollment) == 'completed'
          enrollment.complete
        end
      end
    end
  end
  
  def self.lookup_enrollment_course(enrollment)
    course = @course_lookups[enrollment.course_id]
    course ||= enrollment.course
    @course_lookups[enrollment.course_id] = course
  end
end