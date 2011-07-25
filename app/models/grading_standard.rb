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

class GradingStandard < ActiveRecord::Base
  include Workflow
  attr_accessible :title, :standard_data
  belongs_to :context, :polymorphic => true
  belongs_to :user
  has_many :assignments
  serialize :data
  
  before_save :update_usage_count
  

  workflow do
    state :active
    state :deleted
  end
  
  named_scope :active, :conditions => ['grading_standards.workflow_state != ?', 'deleted']
  
  def update_usage_count
    self.usage_count = self.assignments.active.length
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  set_policy do
    given {|user| true }
    can :read and can :create
    
    given {|user| self.assignments.active.length < 2}
    can :update and can :delete
  end
  
  def update_data(params)
    self.data = params.to_a.sort_by{|i| i[1]}.reverse
  end
  
  def display_name
    res = ""
    res += self.user.name + ", " rescue ""
    res += self.context.name rescue ""
    res = t("unknown_grading_details", "Unknown Details") if res.empty?
    res
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end
  
  def grading_scheme
    res = {}
    self.data.sort_by{|i| i[1]}.reverse.each do |i|
      res[i[0].to_s] = i[1].to_f
    end
    res
  end
  
  def self.standards_for(context, options={})
    user = options[:user]
    context_codes = [context.asset_string]
    if user
      context_codes += ([user] + user.management_contexts).uniq.map(&:asset_string)
    end
    if options[:include_parents]
      context_codes += Account.all_accounts_for(context).map(&:asset_string)
    end
    standards = GradingStandard.active.find_all_by_context_code(context_codes.uniq)
    standards.uniq
  end
  
  def self.sorted_standards_for(context, options={})
    standards_for(context, options).sort_by{|s| [(s.usage_count || 0) > 3 ? 'a' : 'b', (s.title.downcase rescue "zzzzz")]}
  end
  
  def standard_data=(params={})
    params ||= {}
    res = {}
    params.each do |key, row|
      res[row[:name]] = (row[:value].to_f / 100.0) if row[:name] && row[:value]
    end
    self.data = res.to_a.sort_by{|i| i[1]}.reverse
  end
  
  def self.default_grading_standard
    default_grading_scheme.to_a.sort_by{|i| i[1]}.reverse
  end
  
  def self.default_grading_scheme
    {
      "A" => 1.0,
      "A-" => 0.93,
      "B+" => 0.89,
      "B" => 0.86,
      "B-" => 0.83,
      "C+" => 0.79,
      "C" => 0.76,
      "C-" => 0.73,
      "D+" => 0.69,
      "D" => 0.66,
      "D-" => 0.63,
      "F" => 0.6
    }
  end
  
  def self.process_migration(data, migration)
    standards = data['grading_standards'] ? data['grading_standards']: []
    to_import = migration.to_import 'grading_standards'
    standards.each do |standard|
      if standard['migration_id'] && (!to_import || to_import[standard['migration_id']])
        begin
          import_from_migration(standard, migration.context)
        rescue
          migration.add_warning("Couldn't import grading standard \"#{standard[:title]}\"", $!)
        end
      end
    end
  end
  
  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:grading_standards_to_import] && !hash[:grading_standards_to_import][hash[:migration_id]]
    item ||= find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
    item ||= context.grading_standards.new
    item.migration_id = hash[:migration_id]
    item.title = hash[:title]
    begin
      item.data = JSON.parse hash[:data]
    rescue
      #todo - add to message to display to user
    end
    
    item.save!
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item
  end
  
end
