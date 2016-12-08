module MasterCourses::Restrictor
  def self.included(klass)
    klass.cattr_accessor :restricted_column_settings
    klass.restricted_column_settings = {}

    klass.extend ClassMethods
    klass.validate :check_for_restricted_column_changes
    klass.send(:attr_writer, :master_course_restrictions)
  end

  module ClassMethods
    def restrict_columns(edit_type, columns)
      raise "invalid restriction type" unless MasterCourses::LOCK_TYPES.include?(edit_type)
      if self.restricted_column_settings[edit_type] # already set
        Rails.logger.warn("column restrictions for class #{self.name}, type #{edit_type} are already set")
        return # i'd raise, but i'm sure some spring thing will reload this at some point
      end
      columns = Array(columns).map(&:to_s)
      self.restricted_column_settings[edit_type] = columns
    end
  end

  def skip_master_course_validation!
    @skip_master_course_validation = true
  end

  def check_for_restricted_column_changes
    return true if new_record? || @skip_master_course_validation || !is_child_content?
    restrictions = nil
    locked_columns = []
    self.class.base_class.restricted_column_settings.each do |type, columns|
      next unless columns
      changed_columns = (self.changes.keys & columns)
      if changed_columns.any?
        locked_columns << changed_columns if self.master_course_restrictions[type]
      end
    end
    if locked_columns.any?
      self.errors.add(:base, "cannot change column(s): #{locked_columns.join(", ")} - locked by Master Course")
    end
  end

  def editing_restricted?(edit_type=:all) # edit_type can be :all, :any, or a specific type: :content, :settings
    return false unless is_child_content?

    restrictions = self.master_course_restrictions
    return false unless restrictions.present?

    case edit_type
    when :all
      MasterCourses::LOCK_TYPES.all?{|type| restrictions[type]}
    when :any
      MasterCourses::LOCK_TYPES.any?{|type| restrictions[type]}
    when *MasterCourses::LOCK_TYPES
      !!restrictions[edit_type]
    else
      raise "invalid edit type"
    end
  end

  def is_child_content?
    self.migration_id && self.migration_id.start_with?(MasterCourses::MIGRATION_ID_PREFIX)
  end

  def master_course_restrictions
    @master_course_restrictions ||= MasterCourses::MasterContentTag.where(:migration_id => self.migration_id).pluck(:restrictions).first || {}
  end

  def master_course_restrictions_loaded?
    !!@master_course_restrictions
  end

  def self.preload_restrictions(objects)
    objects = Array(objects)
    objects_to_load = objects.select{|obj| obj.is_child_content? && !obj.master_course_restrictions_loaded?}.index_by(&:migration_id)
    migration_ids = objects_to_load.keys
    return unless migration_ids.any?

    objects_to_load.values.each{|obj| obj.master_course_restrictions = {}} # default if restrictions are missing
    all_restrictions = MasterCourses::MasterContentTag.where(:migration_id => migration_ids).pluck(:migration_id, :restrictions)
    all_restrictions.each do |migration_id, restrictions|
      objects_to_load[migration_id].master_course_restrictions = restrictions
    end
  end
end
