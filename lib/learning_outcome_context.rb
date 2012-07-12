module LearningOutcomeContext
  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.has_many :linked_learning_outcomes, :through => :learning_outcome_links, :source => :learning_outcome_content, :conditions => "content_tags.content_type = 'LearningOutcome'"
      klass.has_many :learning_outcome_links, :as => :context, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND content_tags.workflow_state != ?', 'learning_outcome_association', 'deleted']
      klass.has_many :created_learning_outcomes, :class_name => 'LearningOutcome', :as => :context
      klass.has_many :learning_outcome_groups, :as => :context
      klass.send :include, InstanceMethods
    end
  end


  module InstanceMethods
    # return the outcome but only if it's available in either the context or one
    # of the context's associated accounts.
    def available_outcome(outcome_id)
      outcome =
        linked_learning_outcomes.find_by_id(outcome_id) ||
        created_learning_outcomes.find_by_id(outcome_id)
      return outcome if outcome

      associated_accounts.uniq.map do |context|
        outcome = context.available_outcome(outcome_id)
        return outcome if outcome
      end

      return nil
    end

    def available_outcomes
      [self, *associated_accounts].uniq.map do |context|
        [context.linked_learning_outcomes, context.created_learning_outcomes]
      end.flatten.uniq
    end

    def has_outcomes?
      Rails.cache.fetch(['has_outcomes', self].cache_key) do
        linked_learning_outcomes.count > 0
      end
    end

    def root_outcome_group
      group = learning_outcome_groups.find_by_learning_outcome_group_id(nil)
      unless group
        group = learning_outcome_groups.build
        group.building_default = true
        group.save!
      end
      group
    end
  end
end
