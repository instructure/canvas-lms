module DataFixup
  module FixRootOutcomeGroupTitles
    def self.run
      LearningOutcomeGroup.preload(:context).
          where(:title => 'ROOT', :context_type => 'Course').find_in_batches do |batch|
        batch.each { |group| group.update_attribute(:title, group.context.name) }
      end
    end
  end
end
