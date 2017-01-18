module DataFixup
  module ReevaluateIncompleteProgressions
    def self.run
      current_column = 'context_module_progressions.current'
      scope = ContextModuleProgression.where(:workflow_state => ['unlocked', 'started']).where(:current => false)

      ContextModuleProgression.find_ids_in_ranges do |min_id, max_id|
        scope.where(:id => min_id..max_id).preload(:context_module).each do |progression|
          progression.evaluate!
        end
      end
    end
  end
end