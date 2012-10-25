#
# Copyright (C) 2011 Instructure, Inc.
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
  attr_accessible :context, :title, :description, :learning_outcome_group
  belongs_to :learning_outcome_group
  has_many :child_outcome_groups, :class_name => 'LearningOutcomeGroup', :foreign_key => "learning_outcome_group_id"
  has_many :child_outcome_links, :class_name => 'ContentTag', :as => :associated_asset, :conditions => {:tag_type => 'learning_outcome_association', :content_type => 'LearningOutcome'}
  belongs_to :context, :polymorphic => true
  before_save :infer_defaults
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :title
  sanitize_field :description, Instructure::SanitizeField::SANITIZE

  attr_accessor :building_default

  # we prefer using parent_outcome_group over learning_outcome_group,
  # but when I tried naming the association parent_outcome_group, things
  # didn't quite work.
  alias :parent_outcome_group :learning_outcome_group

  def infer_defaults
    self.context ||= self.parent_outcome_group && self.parent_outcome_group.context
    if self.context && !self.context.learning_outcome_groups.empty? && !building_default
      default = self.context.root_outcome_group
      self.learning_outcome_group_id ||= default.id unless self == default
    end
    true
  end
  
  workflow do
    state :active
    state :deleted
  end

  # create a shim for plugins that use this defunct method. this is TEMPORARY.
  # the plugins should update to use the new layout, and once they're updated,
  # this shim removed. DO NOT USE in new code.
  def sorted_content
    # the existing code that requires this shim only occurs when there are
    # either subgroups or outcomes under the group, but not both. and they're
    # from a migration, so the expected order is the migration order.
    subgroups = self.child_outcome_groups.sort_by{ |group| group.migration_id }
    return subgroups unless subgroups.empty?

    self.child_outcome_links.map{ |link| link.content }.sort_by{ |outcome| outcome.migration_id }
  end

  def reorder_content(orders)
    orders ||= {}
    orders = orders.map{|asset_string, position| asset_string}
    orders += self.child_outcome_groups.map(&:asset_string)
    orders += self.child_outcome_links.map(&:asset_string)
    orders = orders.compact.uniq

    # build the updates
    outcome_group_ids = []
    outcome_link_ids = []
    orders.each do |asset_string|
      if asset_string =~ /learning_outcome_group_(\d*)/
        outcome_group_id = $1.to_i
        next if is_ancestor?(outcome_group_id)
        outcome_group_ids << outcome_group_id
      elsif asset_string =~ /content_tag_(\d*)/
        outcome_link_id = $1.to_i
        outcome_link_ids << outcome_link_id
      end
    end

    # update outcome groups
    unless outcome_group_ids.empty?
      sql = "UPDATE learning_outcome_groups SET learning_outcome_group_id=#{self.id} WHERE id IN (#{outcome_group_ids.join(",")}) AND context_type='#{self.context_type}' AND context_id='#{self.context_id}'"
      ContentTag.connection.execute(sql)
    end

    # update outcome links
    unless outcome_link_ids.empty?
      sql = "UPDATE content_tags SET associated_asset_id=#{self.id} WHERE id IN (#{outcome_link_ids.join(",")}) AND context_type='#{self.context_type}' AND context_id='#{self.context_id}'"
      ContentTag.connection.execute(sql)
    end

    orders
  end
  
  def parent_ids
    [learning_outcome_group_id]
  end
  
  # this finds all the ids of the ancestors avoiding relation loops
  # because of old broken behavior a group can have multiple parents, including itself
  def ancestor_ids
    if !@ancestor_ids
      @ancestor_ids = [self.id]
      
      ids_to_check = parent_ids - @ancestor_ids
      until ids_to_check.empty?
        @ancestor_ids += ids_to_check
        
        new_ids = []
        ids_to_check.each do |id|
          group = LearningOutcomeGroup.for_context(self.context).active.find_by_id(id)
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

  # use_outcome should be a lambda that takes an outcome and returns a boolean
  def clone_for(context, parent, opts={})
    parent.add_outcome_group(self, opts)
  end

  # adds a new link to an outcome to this group. does nothing if a link already
  # exists (an outcome can be linked into a context multiple times by multiple
  # groups, but only once per group).
  def add_outcome(outcome)
    # no-op if the outcome is already linked under this group
    outcome_link = child_outcome_links.active.find_by_content_id(outcome.id)
    return outcome_link if outcome_link

    # create new link and in this group
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
    copy = child_outcome_groups.build
    copy.title = original.title
    copy.description = original.description
    copy.context = self.context
    copy.save!

    # copy the group contents
    original.child_outcome_groups.each do |group|
      next if opts[:only] && opts[:only][group.asset_string] != "1"
      copy.add_outcome_group(group, opts)
    end

    original.child_outcome_links.each do |link|
      next if opts[:only] && opts[:only][link.asset_string] != "1"
      copy.add_outcome(link.content)
    end

    # done
    copy
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

  alias_method :destroy!, :destroy
  def destroy
    transaction do
      # delete the children of the group, both links and subgroups, then delete
      # the group itself
      self.child_outcome_links.active.scoped(:include => :content).each{ |outcome_link| outcome_link.destroy }
      self.child_outcome_groups.active.each{ |outcome_group| outcome_group.destroy }
      self.workflow_state = 'deleted'
      save!
    end
  end
  
  def self.import_from_migration(hash, migration, item=nil)
    hash = hash.with_indifferent_access
    if hash[:is_global_standard]
      if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
        hash[:parent_group] ||= LearningOutcomeGroup.global_root_outcome_group
        item ||= LearningOutcomeGroup.global.find_by_migration_id(hash[:migration_id]) if hash[:migration_id]
        item ||= LearningOutcomeGroup.global.find_by_vendor_guid(hash[:vendor_guid]) if hash[:vendor_guid]
        item ||= LearningOutcomeGroup.new
      else
        migration.add_warning(t(:no_global_permission, %{You're not allowed to manage global outcomes, can't add "%{title}"}, :title => hash[:title]))
        return
      end
    else
      context = migration.context
      root_outcome_group = context.root_outcome_group
      item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.learning_outcome_groups.new
      item.context = context
    end
    item.migration_id = hash[:migration_id]
    item.title = hash[:title]
    item.description = hash[:description]
    item.vendor_guid = hash[:vendor_guid]
    item.low_grade = hash[:low_grade]
    item.high_grade = hash[:high_grade]
    
    item.save!
    if hash[:parent_group]
      hash[:parent_group].adopt_outcome_group(item)
    else
      root_outcome_group.adopt_outcome_group(item)
    end
    
    context.imported_migration_items << item if context && context.imported_migration_items && item.new_record?

    if hash[:outcomes]
      hash[:outcomes].each do |child|
        if child[:type] == 'learning_outcome_group'
          child[:parent_group] = item
          LearningOutcomeGroup.import_from_migration(child, migration)
        else
          child[:learning_outcome_group] = item
          LearningOutcome.import_from_migration(child, migration)
        end
      end
    end
    
    item
  end
  
  named_scope :active, lambda{
    {:conditions => ['learning_outcome_groups.workflow_state != ?', 'deleted'] }
  }

  named_scope :global, lambda{
    {:conditions => {:context_id => nil} }
  }

  named_scope :root, lambda{
    {:conditions => {:learning_outcome_group_id => nil} }
  }

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
        group = scope.build :title => 'ROOT'
        group.building_default = true
        group.save!
      end
      group
    end
  end

  def self.global_root_outcome_group(force=true)
    find_or_create_root(nil, force)
  end

  def self.title_order_by_clause(table = nil)
    col = table ? "#{table}.title" : "title"
    best_unicode_collation_key(col)
  end

  module TitleExtension
    # only works with scopes i.e. named_scopes and scoped()
    def find(*args)
      options = args.last.is_a?(::Hash) ? args.last : {}
      scope = scope(:find)
      select = if options[:select]
                 options[:select]
               elsif scope[:select]
                 scope[:select]
               else
                 "#{proxy_scope.quoted_table_name}.*"
               end
      options[:select] = select + ', ' + LearningOutcomeGroup.title_order_by_clause
      super args.first, options
    end
  end

  def self.order_by_title
    scoped(:order => title_order_by_clause, :extend => TitleExtension)
  end
end
