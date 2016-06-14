module DataFixup::RemoveOrphanedContextModuleProgressions
  def self.run
    ContextModuleProgression.
        joins(:context_module).
        where(context_modules: { context_type: 'Course' }).
        where("requirements_met=? OR requirements_met IS NULL", [].to_yaml).
        where("NOT EXISTS (?)", Enrollment.where("course_id=context_id AND enrollments.user_id=context_module_progressions.user_id")).
        find_ids_in_ranges do |first, last|
      ContextModuleProgression.where(id: first..last).delete_all
    end
  end
end
