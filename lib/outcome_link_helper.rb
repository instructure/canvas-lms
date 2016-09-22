module OutcomeLinkHelper
  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.scope :links_for_group, lambda { |group_ids, preload_outcomes=false|
        if preload_outcomes
          klass.active.where(associated_asset_id: group_ids).with_outcome
        else
          klass.active.where(associated_asset_id: group_ids)
        end
      }
      klass.scope :with_outcome, -> { klass.preload(:learning_outcome) }
      klass.send :include, InstanceMethods
      klass.send :extend, ClassMethods
    end
  end

  module InstanceMethods
    class LastLinkToOutcomeNotDestroyed < StandardError
    end

    def update_context(context)
      unless self.is_a?(OutcomeLink)
        self.context(context)
      end
    end

    def can_destroy?
      # if it's a learning outcome link...
      if self.class.name == "OutcomeLink" || self.tag_type == 'learning_outcome_association'
        # and there are no other links to the same outcome in the same context...
        outcome = self.content
        other_ct_links = ContentTag.learning_outcome_links.active.
          where(:context_type => self.context_type, :context_id => self.context_id, :content_id => outcome).
          where.not(id: self.id).exists?
        other_ol_links = OutcomeLink.active.outcome_links_for_context(self.context).
          where(learning_outcome_id: outcome.id).
          where.not(id: self.id).exists?
        if !other_ct_links && !other_ol_links
          # and there are alignments to the outcome (in the link's context for
          # foreign links, in any context for native links)
          alignment_conditions = { :learning_outcome_id => outcome.id }
          native = outcome.context_type == self.context_type && outcome.context_id == self.context_id
          if native
            @should_destroy_outcome = true
          else
            alignment_conditions[:context_id] = self.context_id
            alignment_conditions[:context_type] = self.context_type
          end

          if ContentTag.learning_outcome_alignments.active.where(alignment_conditions).exists?
            # then don't let them delete the link
            return false
          end
        end
      end
      true
    end
  end

  module ClassMethods
    def order_by_outcome_title
      eager_load(:learning_outcome).order(outcome_title_order_by_clause)
    end

    def outcome_title_order_by_clause
      best_unicode_collation_key("learning_outcomes.short_description")
    end

    def delete_for_outcome(outcome)
      ContentTag.learning_outcome_links.active.where(:content_id => outcome).update_all(:workflow_state => 'deleted')
      outcome.outcome_links.update_all(:workflow_state => 'deleted')
    end
  end
end
