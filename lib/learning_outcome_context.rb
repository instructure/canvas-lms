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
    # create a shim for plugins that use the old association name. this is
    # TEMPORARY. the plugins should update to use the new association name, and
    # once they're updated, this shim removed. DO NOT USE in new code.
    def learning_outcomes
      created_learning_outcomes
    end

    # return the outcome but only if it's available in either the context or one
    # of the context's associated accounts.
    def available_outcome(outcome_id, opts={})
      if opts[:allow_global]
        outcome = LearningOutcome.global.where(id: outcome_id).first
        return outcome if outcome
      end

      outcome =
        linked_learning_outcomes.where(id: outcome_id).first ||
        created_learning_outcomes.where(id: outcome_id).first
      return outcome if outcome

      unless opts[:recurse] == false
        (associated_accounts.uniq - [self]).each do |context|
          outcome = context.available_outcome(outcome_id, :recurse => false)
          return outcome if outcome
        end
      end

      return nil
    end

    def available_outcomes
      [self, *associated_accounts].uniq.map do |context|
        [context.linked_learning_outcomes, context.created_learning_outcomes.active]
      end.flatten.uniq
    end

    def has_outcomes?
      Rails.cache.fetch(['has_outcomes', self].cache_key) do
        linked_learning_outcomes.count > 0
      end
    end

    def root_outcome_group(force=true)
      LearningOutcomeGroup.find_or_create_root(self, force)
    end
  end
end
