module OutcomeLinkFinder
  def self.included(klass)
    if klass < ActiveRecord::Base
      if klass == LearningOutcomeGroup
        klass.has_many :legacy_outcome_links, -> { where(tag_type: 'learning_outcome_association', content_type: 'LearningOutcome') }, class_name: 'ContentTag', as: :associated_asset
      else
        klass.has_many :legacy_outcome_links, -> { where(tag_type: 'learning_outcome_association', content_type: 'LearningOutcome') }, class_name: 'ContentTag', as: :content
      end
      klass.has_many :outcome_links
      klass.send :include, InstanceMethods
    end
  end

  module InstanceMethods

    def associated_outcome_links(opts={})
      opts[:active_only] = true if !opts.key?(:active_only)
      if opts[:active_only] && opts[:preload]
        outcome_links.active.with_outcome | legacy_outcome_links.active.with_outcome
      elsif opts[:active_only]
        outcome_links.active | legacy_outcome_links.active
      else
        outcome_links | legacy_outcome_links
      end
    end

    def delete_related_links
      self.outcome_links.update_all(:workflow_state => 'deleted')
      self.legacy_outcome_links.update_all(:workflow_state => 'deleted')
    end

    def find_link_by_outcome_id(id)
      (self.outcome_links.where(content_id: id) | self.legacy_outcome_links.where(content_id: id))[0]
    end
  end
end
