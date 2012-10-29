module DataFixup
  module FixRootOutcomeGroupTitles
    def self.run
      LearningOutcomeGroup.find_in_batches(:include => :context,
        :conditions => {:title => 'ROOT', :context_type => 'Course'}) do |batch|
        batch.each { |group| group.update_attribute(:title, group.context.name) }
      end
    end
  end
end
