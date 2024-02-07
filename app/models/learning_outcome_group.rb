# frozen_string_literal: true

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
  include MasterCourses::Restrictor
  extend RootAccountResolver

  restrict_columns :state, [:workflow_state]

  belongs_to :learning_outcome_group
  belongs_to :source_outcome_group, class_name: "LearningOutcomeGroup", inverse_of: :destination_outcome_groups
  has_many :destination_outcome_groups, class_name: "LearningOutcomeGroup", inverse_of: :source_outcome_group, dependent: :nullify
  has_many :child_outcome_groups, class_name: "LearningOutcomeGroup"
  has_many :child_outcome_links, -> { where(tag_type: "learning_outcome_association", content_type: "LearningOutcome") }, class_name: "ContentTag", as: :associated_asset
  belongs_to :context, polymorphic: [:account, :course]

  before_save :infer_defaults
  resolves_root_account through: ->(group) { group.context_id ? group.context.resolved_root_account_id : 0 }
  validates :vendor_guid, length: { maximum: maximum_string_length, allow_nil: true }
  validates :description, length: { maximum: maximum_text_length, allow_blank: true }
  validates :title, length: { maximum: maximum_string_length, allow_blank: true }
  validates :title, :workflow_state, presence: true
  sanitize_field :description, CanvasSanitize::SANITIZE

  attr_accessor :building_default

  # we prefer using parent_outcome_group over learning_outcome_group,
  # but when I tried naming the association parent_outcome_group, things
  # didn't quite work.
  alias_method :parent_outcome_group, :learning_outcome_group

  workflow do
    state :active
    state :archived
    state :deleted
  end

  def parent_ids
    [learning_outcome_group_id]
  end

  def touch_parent_group
    return if skip_parent_group_touch

    touch
    learning_outcome_group&.touch_parent_group
  end

  # adds a new link to an outcome to this group. does nothing if a link already
  # exists (an outcome can be linked into a context multiple times by multiple
  # groups, but only once per group).
  def add_outcome(outcome, skip_touch: false, migration_id: nil)
    # no-op if the outcome is already linked under this group
    outcome_link = child_outcome_links.active.where(content_id: outcome).first
    return outcome_link if outcome_link

    # create new link and in this group
    touch_parent_group
    child_outcome_links.create(
      content: outcome,
      context: context || self,
      skip_touch:,
      migration_id:
    )
  end

  OutcomeLink = Struct.new(:id, :content_id, :associated_asset_id, :context_id, :context_type, :workflow_state)

  def self.bulk_link_outcome(outcome, groups, root_account_id:)
    groups = groups.preload(:learning_outcome_group, :context)
    timestamp = Time.now.utc
    touch_set = Set.new

    new_tags = groups.map do |group|
      touch_set << group.context
      tgroup = group
      while tgroup && !touch_set.include?(tgroup)
        touch_set << tgroup
        tgroup = tgroup.learning_outcome_group
      end

      {
        tag_type: "learning_outcome_association",
        content_id: outcome.id,
        content_type: outcome.class,
        associated_asset_id: group.id,
        associated_asset_type: group.class,
        context_id: group.context_id || group.id,
        context_type: group.context_id.present? ? group.context_type : LearningOutcomeGroup,
        root_account_id:,
        title: outcome.title,
        comments: "",
        context_code: "#{group.context_type.to_s.underscore}_#{group.context_id}",
        created_at: timestamp,
        updated_at: timestamp,
      }
    end

    tags = ContentTag.insert_all(new_tags, returning: %w[id content_id associated_asset_id context_id context_type workflow_state])

    tags.rows.each do |tag|
      link = OutcomeLink.new(tag[0], tag[1], tag[2], tag[3], tag[4], tag[5])
      Canvas::LiveEvents.learning_outcome_link_created(link)
    rescue => e
      Canvas::Errors.capture_exception(:learning_outcome_link_creation, e, :error)
    end

    touch_set.group_by(&:class).each do |cls, idset|
      cls.where(id: idset).update_all(updated_at: timestamp)
    end
  end

  def sync_source_group
    transaction do
      raise ActiveRecord::Rollback unless source_outcome_group

      source_outcome_group.child_outcome_links.active.each do |link|
        add_outcome(link.content, skip_touch: true)
      end

      source_outcome_group.child_outcome_groups.active.each do |source_child_group|
        target_child_group = child_outcome_groups.find_by(source_outcome_group_id: source_child_group.id)

        if target_child_group
          unless target_child_group.workflow_state == "active"
            target_child_group.root_account_id = context.resolved_root_account_id
            target_child_group.workflow_state = "active"
            target_child_group.save!
          end
        else
          target_child_group = child_outcome_groups.build
          target_child_group.title = source_child_group.title
          target_child_group.description = source_child_group.description
          target_child_group.vendor_guid = source_child_group.vendor_guid
          target_child_group.source_outcome_group = source_child_group
          target_child_group.context = context
          target_child_group.skip_parent_group_touch = true
          target_child_group.save!
        end

        target_child_group.sync_source_group
      end
    end
  end

  # copies an existing outcome group, form this context or another, into this
  # group. if :only is specified, only those immediate child outcomes included
  # in :only are copied; subgroups are only copied if :only is absent.
  #
  # TODO: this is certainly not the behavior we want, but it matches existing
  # behavior, and I'm not getting into a full refactor of copy course in this
  # commit!
  def add_outcome_group(original, opts = {})
    # copy group into this group
    transaction do
      copy = child_outcome_groups.build
      copy.title = original.title
      copy.description = original.description
      copy.vendor_guid = original.vendor_guid
      copy.context = context
      copy.skip_parent_group_touch = true
      copy.save!

      # copy the group contents
      copy_opts = opts.reverse_merge(skip_touch: true)
      original.child_outcome_groups.active.each do |group|
        next if opts[:only] && opts[:only][group.asset_string] != "1"

        copy.add_outcome_group(group, copy_opts)
      end

      original.child_outcome_links.active.each do |link|
        next if opts[:only] && opts[:only][link.asset_string] != "1"

        copy.add_outcome(link.content, skip_touch: true)
      end

      context&.touch unless opts[:skip_touch]
      touch_parent_group

      # done
      copy
    end
  end

  # moves an existing outcome link from the same context to be under this
  # group.
  def adopt_outcome_link(outcome_link, opts = {})
    return if context && context != outcome_link.context
    # no-op if the group is global and the link isn't
    return if context.nil? && outcome_link.context_type != "LearningOutcomeGroup"
    # no-op if we're already the parent
    return outcome_link if outcome_link.associated_asset == self

    # update context_id if global
    outcome_link.context_id = id if context.nil?

    # change the parent
    outcome_link.associated_asset = self
    outcome_link.save!
    touch_parent_group unless opts[:skip_parent_group_touch]
    outcome_link
  end

  # moves an existing outcome group from the same context to be under this
  # group. cannot move an ancestor of the group.
  def adopt_outcome_group(group)
    # can only move within context, and no cycles!
    return unless group.context == context
    return if is_ancestor?(group.id)

    # no-op if we're already the parent
    return group if group.parent_outcome_group == self

    # change the parent
    group.learning_outcome_group_id = id
    group.save!
    group
  end

  attr_accessor :skip_tag_touch, :skip_parent_group_touch
  alias_method :destroy_permanently!, :destroy
  def destroy
    transaction do
      # delete the children of the group, both links and subgroups, then delete
      # the group itself
      child_outcome_links.active.preload(:content).each do |outcome_link|
        outcome_link.skip_touch = true if @skip_tag_touch
        outcome_link.destroy
      end
      child_outcome_groups.active.each do |outcome_group|
        outcome_group.skip_tag_touch = true if @skip_tag_touch
        outcome_group.destroy
      end

      self.workflow_state = "deleted"
      save!
    end
  end

  def archive!
    # Only active groups can be archived
    if workflow_state == "active"
      self.workflow_state = "archived"
      self.archived_at = Time.now.utc
      save!
    elsif workflow_state == "deleted"
      raise ActiveRecord::RecordNotSaved, "Cannot archive a deleted LearningOutcomeGroup"
    end
  end

  def unarchive!
    # Only archived groups can be unarchived
    if workflow_state == "archived"
      self.workflow_state = "active"
      self.archived_at = nil
      save!
    elsif workflow_state == "deleted"
      raise ActiveRecord::RecordNotSaved, "Cannot unarchive a deleted LearningOutcomeGroup"
    end
  end

  scope :active, -> { where("learning_outcome_groups.workflow_state NOT IN ('deleted', 'archived')") }
  scope :active_first, -> { order(Arel.sql("CASE WHEN workflow_state = 'active' THEN 0 ELSE 1 END")) }
  scope :archived, -> { where("learning_outcome_groups.workflow_state = 'archived' AND learning_outcome_groups.archived_at IS NOT NULL") }

  scope :global, -> { where(context_id: nil) }

  scope :root, -> { where(learning_outcome_group_id: nil) }

  def self.for_context(context)
    context ? context.learning_outcome_groups : LearningOutcomeGroup.global
  end

  def self.find_or_create_root(context, force)
    scope = for_context(context)
    # do this in a transaction, so parallel calls don't create multiple roots
    # TODO: clean up contexts that already have multiple root outcome groups
    transaction do
      group = scope.active.root.take
      if !group && force
        group = scope.build title: context.try(:name) || "ROOT"
        group.building_default = true
        GuardRail.activate(:primary) do
          # during course copies/imports, observe may be disabled but import job will
          # not be aware of this lazy object creation
          ActiveRecord::Base.observers.enable LiveEventsObserver do
            group.save!
          end
        end
      end
      group
    end
  end

  def self.global_root_outcome_group(force = true)
    find_or_create_root(nil, force)
  end

  def self.order_by_title
    scope = self
    scope = scope.select("learning_outcome_groups.*") unless all.select_values.present?
    scope.select(title_order_by_clause).order(title_order_by_clause)
  end

  # this finds all the ids of the ancestors avoiding relation loops
  # because of old broken behavior a group can have multiple parents, including itself
  def ancestor_ids
    unless @ancestor_ids
      @ancestor_ids = [id]

      ids_to_check = parent_ids - @ancestor_ids
      until ids_to_check.empty?
        @ancestor_ids += ids_to_check

        new_ids = []
        ids_to_check.each do |id|
          group = LearningOutcomeGroup.for_context(context).active.where(id:).first
          new_ids += group.parent_ids if group
        end

        ids_to_check = new_ids.uniq - @ancestor_ids
      end
    end

    @ancestor_ids
  end

  private

  def infer_defaults
    self.context ||= parent_outcome_group&.context
    if self.context&.learning_outcome_groups&.exists? && !building_default
      default = self.context.root_outcome_group
      self.learning_outcome_group_id ||= default.id unless self == default
    end
    true
  end

  def is_ancestor?(id)
    ancestor_ids.member?(id)
  end

  private_class_method def self.title_order_by_clause(table = nil)
    col = table ? "#{table}.title" : "title"
    best_unicode_collation_key(col)
  end
end
