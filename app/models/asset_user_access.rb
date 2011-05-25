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

# asset_code is used to specify the 'asset' or idea being accessed
# asset_group_code is for the group
# so, for example, the asset could be an assignment, the group would be the assignment_group
class AssetUserAccess < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  belongs_to :user
  has_many :page_views
  has_many :asset_access_ranges
  before_save :infer_defaults
  attr_accessible :user, :asset_code
  
  named_scope :for_context, lambda{|context|
    {:conditions => ["asset_user_accesses.context_id = ? AND asset_user_accesses.context_type = ?", context.id, context.class.to_s]}
  }
  named_scope :for_user, lambda{|user|
    {:conditions => ["asset_user_accesses.user_id = ?", user.id] }
  }
  named_scope :most_recent, {:order => 'updated_at DESC'}
  
  def category
    self.asset_category
  end
  
  def infer_defaults
    self.display_name ||= asset_display_name
  end
  
  def category=(val)
    self.asset_category = val
  end
  
  def self.by_category(list, old_list=[])
    res = {}.with_indifferent_access
    res[:categories] = {}
    res[:totals] = {}
    res[:prior_totals] = {}
    Rails.cache.fetch(['access_by_category', list.first, list.last, list.length].cache_key) do
      list.each{|a| 
        a.category ||= 'unknown'
        cat = res[:categories][a.category] || {}
        cat[:view_tally] ||= 0
        cat[:view_tally] += a.view_score || 0
        cat[:participate_tally] ||= 0
        cat[:participate_tally] += a.participate_score || 0
        cat[:interaction_seconds] = (cat[:interaction_seconds] || 0) + ((a.interaction_seconds || 30) * a.view_score)
        cat[:user_ids] ||= {}
        cat[:user_ids][a.user_id] = (cat[:user_ids][a.user_id] || 0) + 1
        cat[:membership_types] ||= {}
        cat[:membership_types][a.membership_type || "Other"] = (cat[:membership_types][a.membership_type || "Other"] || 0) + (a.view_score || 0)
        cat[:assets] ||= {}
        cat[:assets][a.asset_code] ||= {}
        cat[:assets][a.asset_code][:view_tally] ||= 0
        cat[:assets][a.asset_code][:view_tally] += a.view_score || 0
        cat[:assets][a.asset_code][:participate_tally] ||= 0
        cat[:assets][a.asset_code][:participate_tally] += a.participate_score || 0
        cat[:assets][a.asset_code][:display_name] ||= a.display_name
        res[:categories][a.category] = cat
        res[:totals][:view_tally] ||= 0
        res[:totals][:view_tally] += a.view_score || 0
        res[:totals][:participate_tally] ||= 0
        res[:totals][:participate_tally] += a.participate_score || 0
      }
      (old_list || []).each{|a| 
        a.category ||= 'unknown'
        cat = res[:categories][a.category] || {}
        cat[:prior_view_tally] ||= 0
        cat[:prior_view_tally] += a.view_score || 0
        cat[:participate_tally] ||= 0
        cat[:participate_tally] += a.participate_score || 0
        cat[:prior_assets] ||= {}
        cat[:prior_assets][a.asset_code] ||= {}
        cat[:prior_assets][a.asset_code][:view_tally] ||= 0
        cat[:prior_assets][a.asset_code][:view_tally] += a.view_score || 0
        cat[:prior_assets][a.asset_code][:participate_tally] ||= 0
        cat[:prior_assets][a.asset_code][:participate_tally] += a.participate_score || 0
        cat[:prior_assets][a.asset_code][:display_name] ||= a.display_name
        res[:categories][a.category] = cat
        res[:prior_totals][:view_tally] ||= 0
        res[:prior_totals][:view_tally] += a.view_score || 0
        res[:prior_totals][:participate_tally] ||= 0
        res[:prior_totals][:participate_tally] += a.participate_score || 0
      }
      res[:categories].each{|key, val| 
        res[:categories][key][:participate_average] = (res[:categories][key][:participate_tally].to_f / res[:totals][:participate_tally].to_f * 100).round / 100.0 rescue 0
        res[:categories][key][:view_average] = (res[:categories][key][:view_tally].to_f / res[:totals][:view_tally].to_f * 100).round rescue 0
        res[:categories][key][:interaction_seconds_average] = (res[:categories][key][:interaction_seconds].to_f / res[:categories][key][:view_tally].to_f * 100).round / 100.0 rescue 0
      }
      res
    end
  end
  
  def self.summarize_asset_accesses
    @accesses = AssetUserAccess.to_be_summarized
    if !@accesses.empty?
      @accesses.each{|a| a.generate_summaries }
    end
  end
  
  def display_name
    # repair existing AssetUserAccesses that have bad display_names
    if read_attribute(:display_name) == asset_code
      better_display_name = asset_display_name
      if better_display_name != asset_code
        update_attribute(:display_name, better_display_name)
      end
    end
    read_attribute(:display_name)
  end
  
  def asset_display_name
    if self.asset.respond_to?(:title) && !self.asset.title.nil?
      asset.title
    elsif self.asset.is_a? Enrollment
      asset.user.name
    else
      self.asset_code
    end
  end
  
  def context_code
    "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  
  def readable_name
    if self.asset_code && self.asset_code.match(/\:/)
      split = self.asset_code.split(/\:/)
      if split[1] == self.context_code
        # TODO: i18n
        "#{self.context_type} #{split[0].titleize}"
      else
        self.display_name
      end
    else
      re = Regexp.new("#{self.asset_code} - ")
      self.display_name.nil? ? "" : self.display_name.gsub(re, "")
    end
  end
  
  def asset
    asset_code, general = self.asset_code.split(":").reverse
    code_split = asset_code.split("_")
    asset = Context.find_asset_by_asset_string(asset_code, context)
    asset
  end
  memoize :asset
  
  def asset_class_name
    self.asset.class.name.underscore if self.asset
  end
  
  def self.infer_asset(code)
    asset_code, general = code.split(":").reverse
    code_split = asset_code.split("_")
    asset = Context.find_asset_by_asset_string(asset_code)
    asset
  end
  
  def generate_summaries
    contexts = []
    obj = self
    while (obj.respond_to?(:context) && obj.context) || (obj.respond_to?(:account) && obj.account)
      if (obj.respond_to?(:context) && obj.context)
        contexts << obj.context
        obj = obj.context
      else
        contexts << obj.account
        obj = obj.account
      end
    end
    page_views = self.page_views
    found_ranges = {}
    page_views.each do |view|
      view_week = view.created_at.to_date
      # Week range is Monday to Sunday
      view_week = (view_week - 1) - (view_week - 1).wday + 1
      view_month = Date.new(y=view.created_at.year, m=view.created_at.month, d=1) #view.created_at.strftime("%m:%Y")
      if !found_ranges[view_week]
        contexts.each do |context|
          week_range = self.asset_access_ranges.find_by_start_on_and_end_on_and_context_id_and_context_type(view_week, view_week + 6, context.id, context.class.to_s)
          week_range ||= self.asset_access_ranges.build(:start_on => view_week, :end_on => view_week + 6, :context => context)
          week_range.user_id = self.user_id
          week_range.asset_code = self.asset_code
          week_range.save
        end
      end
      if !found_ranges[view_month]
        contexts.each do |context|
          month_range = self.asset_access_ranges.find_by_start_on_and_end_on_and_context_id_and_context_type(view_month, (view_month >> 1) - 1, context.id, context.class.to_s)
          month_range ||= self.asset_access_ranges.build(:start_on => view_month, :end_on => (view_month >> 1) - 1, :context => context)
          month_range.user_id = self.user_id
          month_range.asset_code = self.asset_code
          month_range.save
        end
      end
      found_ranges[view_week] = true
      found_ranges[view_month] = true
    end
    
    self.asset_access_ranges.incomplete.each do |range|
      views = page_views.select{|v| v.created_at >= range.start_on && v.created_at <= range.end_on.tomorrow}
      range.view_score = 0
      range.participate_score = 0
      range.interaction_seconds = 0
      range.action_level = 'view'
      views.each do |view|
        range.view_score += 1
        range.asset_category ||= self.asset_category
        range.display_name = self.display_name
        range.membership_type ||= self.membership_type
        range.participate_score += 1 if view.participated
        range.interaction_seconds += view.interaction_seconds if view.interaction_seconds
        range.action_level = 'participate' if view.participated
      end
      range.workflow_state = 'complete' if Time.now > range.end_on.tomorrow
      range.save
    end
    self.summarized_at = Time.now
    self.save
  end
  
  named_scope :to_be_summarized, :order => 'updated_at', :conditions => ['summarized_at IS NULL'], :limit => 500
  named_scope :to_be_resummarized, :order => 'summarized_at', :conditions => ['summarized_at < ?', 24.hours.ago], :limit => 5
end
