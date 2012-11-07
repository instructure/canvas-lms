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
  named_scope :for_users, lambda{|users|
    {:conditions => ["asset_user_accesses.user_id IN (?)", users.map(&:id)] }
  }
  named_scope :participations, {:conditions => { :action_level => 'participate' }}
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
end
