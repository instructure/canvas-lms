#
# Copyright (C) 2011 - present Instructure, Inc.
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

class LearningOutcomeGroup < ActiveRecord::Base
  include Workflow
  include OutcomeAttributes
  include MasterCourses::Restrictor
  restrict_columns :state, [:workflow_state]

  belongs_to :learning_outcome_group
  has_many :child_outcome_groups, :class_name => 'LearningOutcomeGroup', :foreign_key => "learning_outcome_group_id"
  has_many :child_outcome_links, -> { where(tag_type: 'learning_outcome_association', content_type: 'LearningOutcome') }, class_name: 'ContentTag', as: :associated_asset
  belongs_to :context, polymorphic: [:account, :course]

  before_save :infer_defaults
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :title, :workflow_state
  sanitize_field :description, CanvasSanitize::SANITIZE

  attr_accessor :building_default

  # we prefer using parent_outcome_group over learning_outcome_group,
  # but when I tried naming the association parent_outcome_group, things
  # didn't quite work.
  alias :parent_outcome_group :learning_outcome_group

  workflow do
    state :active
    state :deleted
  end

  def parent_ids
    [learning_outcome_group_id]
  end

  def touch_parent_group
    return if self.skip_parent_group_touch
    self.touch
    self.learning_outcome_group.touch_parent_group if self.learning_outcome_group
  end

  # adds a new link to an outcome to this group. does nothing if a link already
  # exists (an outcome can be linked into a context multiple times by multiple
  # groups, but only once per group).
  def add_outcome(outcome)
    # no-op if the outcome is already linked under this group
    outcome_link = child_outcome_links.active.where(content_id: outcome).first
    return outcome_link if outcome_link

    # create new link and in this group
    touch_parent_group
    child_outcome_links.create(
      :content => outcome,
      :context => self.context || self)
  end

  # copies an existing outcome group, form this context or another, into this
  # group. if :only is specified, only those immediate child outcomes included
  # in :only are copied; subgroups are only copied if :only is absent.
  #
  # TODO: this is certainly not the behavior we want, but it matches existing
  # behavior, and I'm not getting into a full refactor of copy course in this
  # commit!
  def add_outcome_group(original, opts={})
    # copy group into this group
    transaction do
      copy = child_outcome_groups.build
      copy.title = original.title
      copy.description = original.description
      copy.vendor_guid = original.vendor_guid
      copy.context = self.context
      copy.save!

      # copy the group contents
      original.child_outcome_groups.active.each do |group|
        next if opts[:only] && opts[:only][group.asset_string] != "1"
        copy.add_outcome_group(group, opts)
      end

      original.child_outcome_links.active.each do |link|
        next if opts[:only] && opts[:only][link.asset_string] != "1"
        copy.add_outcome(link.content)
      end

      touch_parent_group
      # done
      copy
    end
  end

  # moves an existing outcome link from the same context to be under this
  # group.
  def adopt_outcome_link(outcome_link, opts={})
    # no-op if we're already the parent
    return unless outcome_link.context == self.context
    return outcome_link if outcome_link.associated_asset == self

    # change the parent
    outcome_link.associated_asset = self
    outcome_link.save!
    touch_parent_group
    outcome_link
  end

  # moves an existing outcome group from the same context to be under this
  # group. cannot move an ancestor of the group.
  def adopt_outcome_group(group, opts={})
    # can only move within context, and no cycles!
    return unless group.context == self.context
    return if is_ancestor?(group.id)

    # no-op if we're already the parent
    return group if group.parent_outcome_group == self

    # change the parent
    group.learning_outcome_group_id = self.id
    group.save!
    group
  end

  attr_accessor :skip_tag_touch, :skip_parent_group_touch
  alias_method :destroy_permanently!, :destroy
  def destroy
    transaction do
      # delete the children of the group, both links and subgroups, then delete
      # the group itself
      self.child_outcome_links.active.preload(:content).each do |outcome_link|
        outcome_link.skip_touch = true if @skip_tag_touch
        outcome_link.destroy
      end
      self.child_outcome_groups.active.each do |outcome_group|
        outcome_group.skip_tag_touch = true if @skip_tag_touch
        outcome_group.destroy
      end

      self.workflow_state = 'deleted'
      save!
    end
  end

  scope :active, -> { where("learning_outcome_groups.workflow_state<>'deleted'") }

  scope :global, -> { where(:context_id => nil) }

  scope :root, -> { where(:learning_outcome_group_id => nil) }

  def self.for_context(context)
    context ? context.learning_outcome_groups : LearningOutcomeGroup.global
  end

  def self.find_or_create_root(context, force)
    scope = for_context(context)
    # do this in a transaction, so parallel calls don't create multiple roots
    # TODO: clean up contexts that already have multiple root outcome groups
    transaction do
      group = scope.active.root.first
      if !group && force
        group = scope.build :title => context.try(:name) || 'ROOT'
        group.building_default = true
        group.save!
      end
      group
    end
  end

  def self.global_root_outcome_group(force=true)
    find_or_create_root(nil, force)
  end

  def self.order_by_title
    scope = self
    scope = scope.select("learning_outcome_groups.*") if !all.select_values.present?
    scope.select(title_order_by_clause).order(title_order_by_clause)
  end

  private

  def infer_defaults
    self.context ||= self.parent_outcome_group && self.parent_outcome_group.context
    if self.context && self.context.learning_outcome_groups.exists? && !building_default
      default = self.context.root_outcome_group
      self.learning_outcome_group_id ||= default.id unless self == default
    end
    true
  end

  # this finds all the ids of the ancestors avoiding relation loops
  # because of old broken behavior a group can have multiple parents, including itself
  def ancestor_ids
    unless @ancestor_ids
      @ancestor_ids = [self.id]

      ids_to_check = parent_ids - @ancestor_ids
      until ids_to_check.empty?
        @ancestor_ids += ids_to_check

        new_ids = []
        ids_to_check.each do |id|
          group = LearningOutcomeGroup.for_context(self.context).active.where(id: id).first
          new_ids += group.parent_ids if group
        end

        ids_to_check = new_ids.uniq - @ancestor_ids
      end
    end

    @ancestor_ids
  end

  def is_ancestor?(id)
    ancestor_ids.member?(id)
  end

  private_class_method def self.title_order_by_clause(table = nil)
    col = table ? "#{table}.title" : "title"
    best_unicode_collation_key(col)
  end
end
