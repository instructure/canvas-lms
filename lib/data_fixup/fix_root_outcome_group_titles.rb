module DataFixup
  module FixRootOutcomeGroupTitles
    def self.run
      LearningOutcomeGroup.includes(:context).
          where(:title => 'ROOT', :context_type => 'Course').find_in_batches do |batch|
        LearningOutcomeGroup.send(:with_exclusive_scope) do
          batch.each { |group| group.update_attribute(:title, group.context.name) }
        end
      end
    end
  end
end
