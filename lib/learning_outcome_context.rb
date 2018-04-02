#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module LearningOutcomeContext
  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.has_many :learning_outcome_links, -> { where("content_tags.tag_type='learning_outcome_association' AND content_tags.workflow_state<>'deleted'") }, as: :context, inverse_of: :context, class_name: 'ContentTag'
      klass.has_many :linked_learning_outcomes, -> { where(content_tags: { content_type: 'LearningOutcome' }) }, through: :learning_outcome_links, source: :learning_outcome_content
      klass.has_many :created_learning_outcomes, :class_name => 'LearningOutcome', :as => :context, :inverse_of => :context
      klass.has_many :learning_outcome_groups, :as => :context, :inverse_of => :context
      klass.send :include, InstanceMethods

      klass.after_save :update_root_outcome_group_name, if: -> { saved_change_to_name? }
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

    def update_root_outcome_group_name
      root = root_outcome_group(false)
      return unless root
      self.class.connection.after_transaction_commit do
        root.update! title: self.name
      end
    end
  end
end
