module Submittable
  def self.included(klass)
    klass.belongs_to :assignment
    klass.belongs_to :old_assignment, class_name: 'Assignment'
    klass.has_many :assignment_student_visibilities, :through => :assignment

    klass.scope :visible_to_students_in_course_with_da, lambda { |user_ids, course_ids|
      klass.without_assignment_in_course(course_ids)
        .union(klass.joins_assignment_student_visibilities(user_ids, course_ids))
    }

    klass.scope :without_assignment_in_course, lambda { |course_ids|
      klass.where(context_id: course_ids, context_type: "Course").where(assignment_id: nil)
    }

    klass.scope :joins_assignment_student_visibilities, lambda { |user_ids, course_ids|
      klass.joins(:assignment_student_visibilities)
        .where(assignment_student_visibilities: { user_id: user_ids, course_id: course_ids })
    }
  end

  def sync_assignment
    if (a = self.assignment)
      a.title = self.title
      name = self.class.name.underscore
      a.submission_types = name
      a.saved_by = name.to_sym
      a.workflow_state = self.published? ? "published" : "unpublished"
    end
  end

  def for_assignment?
    name = self.class.name.underscore
    self.assignment && self.assignment.submission_types =~ /#{name}/
  end

  def restore(from=nil)
    self.workflow_state = 'unpublished'
    self.save

    if from != :assignment && self.for_assignment? && self.assignment.deleted?
      name = self.class.name.underscore
      self.assignment.restore(name.to_sym)
    end
  end

  def unlink!(type)
    @saved_by = type
    self.assignment = nil
    self.destroy
  end

  def restore_old_assignment
    return nil unless self.old_assignment && self.old_assignment.deleted?
    self.old_assignment.workflow_state = 'published'
    name = self.class.name.underscore
    self.old_assignment.saved_by = name.to_sym
    self.old_assignment.save(:validate => false)
    self.old_assignment
  end

  def update_assignment
    if self.deleted?
      self.assignment.destroy if self.for_assignment? && !self.assignment.deleted?
    else
      if !self.assignment_id && @old_assignment_id
        self.context_module_tags.each(&:confirm_valid_module_requirements)
      end
      if @old_assignment_id
        Assignment.where(
          id: @old_assignment_id,
          context: self.context,
          submission_types: 'wiki_page'
        ).update_all(workflow_state: 'deleted', updated_at: Time.now.utc)
      elsif self.assignment && @saved_by != :assignment
        self.clear_changes_information unless CANVAS_RAILS4_0 # needed to prevent an infinite loop in rails 4.2
        self.sync_assignment
        self.assignment.save
      end
    end
  end
  protected :update_assignment

  def default_submission_values
    if self.assignment_id != self.assignment_id_was
      @old_assignment_id = self.assignment_id_was
    end
    if self.assignment_id
      self.assignment_id = nil unless self.assignment &&
        self.assignment.context == self.context ||
        self.try(:root_topic).try(:assignment_id) == self.assignment_id
      self.old_assignment_id = self.assignment_id if self.assignment_id
    end
  end
  protected :default_submission_values
end
