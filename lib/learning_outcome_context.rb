module LearningOutcomeContext
  def self.included(klass)
    if klass < ActiveRecord::Base
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

    def linked_learning_outcomes(opts={})
      ids_in_context = self.learning_outcome_links.pluck(:content_id)
      outcome_ids = opts[:outcome_ids] ? ids_in_context & opts[:outcome_ids] : ids_in_context
      LearningOutcome.where(id: outcome_ids).active
    end

    def learning_outcome_links
      ContentTag.from("(#{content_tag_query.to_sql} UNION #{outcome_link_query.to_sql}) AS content_tags").active
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

    private

    def content_tag_query
      ContentTag.where("
        content_tags.tag_type = 'learning_outcome_association'
        AND content_tags.context_id = '#{self.id}'").
        select(
          'learning_outcome_id,
          content_id,
          associated_asset_id,
          associated_asset_type,
          workflow_state,
          content_type,
          context_type,
          context_id,
          tag_type,
          id'
        )
    end

    def outcome_link_query
      OutcomeLink.select("
        outcome_links.learning_outcome_id,
        outcome_links.learning_outcome_id       AS content_id,
        outcome_links.learning_outcome_group_id AS associated_asset_id,
        'LearningOutcome'                       AS associated_asset_type,
        outcome_links.workflow_state            AS workflow_state,
        'LearningOutcome'                       AS content_type,
        NULL                                    AS tag_type,
        NULL                                    AS context_type,
        '#{self.id}'                            AS context_id,
        outcome_links.id").joins("
          INNER JOIN #{LearningOutcomeGroup.quoted_table_name} log ON log.context_id = #{self.id}
          AND log.context_type = '#{self.class}'").
        where("log.id = outcome_links.learning_outcome_group_id")
    end
  end
end
