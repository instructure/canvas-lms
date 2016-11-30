#
# Copyright (C) 2016 Instructure, Inc.
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
#

class OutcomeLink < ActiveRecord::Base
  include Workflow
  include OutcomeLinkHelper

  attr_accessible :learning_outcome_group, :learning_outcome
  attr_accessor :skip_touch

  belongs_to :learning_outcome_group
  belongs_to :learning_outcome

  def context
    learning_outcome_group.context || learning_outcome_group
  end

  def context_id
    learning_outcome_group.context_id || learning_outcome_group.id
  end

  def context_type
    learning_outcome_group.context_type || LearningOutcomeGroup.to_s
  end

  delegate :title, to: :learning_outcome

  # aliases for compatibility with legacy content_tag
  alias_method :associated_asset, :learning_outcome_group
  alias_method :learning_outcome_content, :learning_outcome
  alias_method :content, :learning_outcome
  alias_attribute :content_id, :learning_outcome_id
  alias_attribute :associated_asset_id, :learning_outcome_group_id

  before_save :default_values

  scope :active, -> { where(:workflow_state => 'active') }
  scope :outcome_links_for_context, lambda { |context|
    context.instance_of?(LearningOutcomeGroup) ?
    where(learning_outcome_group: context) :
    eager_load(:learning_outcome_group).where(learning_outcome_groups: {
      context_id: context.id,
      context_type: context.class.to_s
    })
  }

  workflow do
    state :active do
      event :destroy, :transitions_to => :deleted
    end
    state :deleted do
      event :restore, :transitions_to => :active
    end
  end

  def associated_asset=(learning_outcome_group)
    self.learning_outcome_group = learning_outcome_group
  end

  def default_values
    @workflow_state = "active"
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    unless can_destroy?
      raise LastLinkToOutcomeNotDestroyed.new('Link is the last link to an aligned outcome. Remove the alignment and then try again')
    end

    self.workflow_state = 'deleted'
    self.save!

    # after deleting the last native link to an unaligned outcome, delete the
    # outcome. we do this here instead of in LearningOutcome#destroy because
    # (a) LearningOutcome#destroy *should* only ever be called from here, and
    # (b) we've already determined other_link and native
    if @should_destroy_outcome
      self.content.destroy
    end

    true
  end

end