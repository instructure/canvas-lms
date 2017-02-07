module MasterCourses::CollectionRestrictor
  # this is super similar to the normal Restrictor - the main difference is that these models are locked by some parent object
  # e.g. this is a quiz question locked by a quiz
  # even though they do a lot of the same things, i couldn't figure out a way to keep them together that didn't make things super convoluted

  def self.included(klass)
    klass.include MasterCourses::Restrictor::CommonMethods
    klass.extend ClassMethods

    klass.cattr_accessor :collection_owner_association # this is the association to find the quiz

    klass.after_update :mark_downstream_changes

    # quiz questions don't even get instantiated normally on import so
    # we'll have to directly hook this code into the importer
    # this callback is silly but i'm adding it just in case
    klass.before_update :check_before_overwriting_child_content_on_import
  end

  module ClassMethods
    def restrict_columns(edit_type, columns)
      raise "set the collection owner first" unless self.collection_owner_association

      super
      owner_class = self.reflections[self.collection_owner_association.to_s].klass
      owner_class.restrict_columns(edit_type, pseudocolumn_for_type(edit_type)) # e.g. add "assessment_questions_content" as a restricted column
    end

    def pseudocolumn_for_type(type) # prepend with table name because it looks better than "Quizzes::QuizQuestion"
      "#{self.table_name}_#{type}"
    end
  end

  def owner_for_restrictions
    self.send(self.class.base_class.collection_owner_association)
  end

  # delegate to the owner
  def is_child_content?
    owner_for_restrictions && owner_for_restrictions.is_child_content?
  end

  def master_course_restrictions
    self.owner_for_restrictions.master_course_restrictions
  end

  def mark_downstream_changes
    return if @importing_migration || !is_child_content? # don't mark changes on import

    # instead of marking the exact columns - i'm just going to be lazy and mark the edit type on the owner, e.g. "quiz_questions_content"
    changed_types = []
    self.class.base_class.restricted_column_settings.each do |edit_type, columns|
      if (self.changes.keys & columns).any?
        changed_types << self.class.pseudocolumn_for_type(edit_type) # pretend it's sort of like a column in the downstream changes
      end
    end
    self.owner_for_restrictions.mark_downstream_changes(changed_types) if changed_types.any? # store changes on owner
  end

  def check_before_overwriting_child_content_on_import
    return unless @importing_migration && is_child_content?
    raise "was too lazy to implement this because i didn't think we needed it, sorry not sorry"
  end
end
