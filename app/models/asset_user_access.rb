#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  belongs_to :context, polymorphic: [:account, :course, :group, :user], polymorphic_prefix: true
  belongs_to :user
  has_many :page_views
  before_save :infer_defaults
  attr_accessible :user, :asset_code

  scope :for_context, lambda { |context| where(:context_id => context, :context_type => context.class.to_s) }
  scope :for_user, lambda { |user| where(:user_id => user) }
  scope :participations, -> { where(:action_level => 'participate') }
  scope :most_recent, -> { order('updated_at DESC') }

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
    return nil unless asset
    if self.asset.respond_to?(:title) && !self.asset.title.nil?
      asset.title
    elsif self.asset.is_a? Enrollment
      asset.user.name
    elsif self.asset.respond_to?(:name) && !self.asset.name.nil?
      asset.name
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

      if split[1].match(/course_\d+/)
        case split[0]
        when "announcements"
          t("Course Announcements")
        when "assignments"
          t("Course Assignments")
        when "calendar_feed"
          t("Course Calendar")
        when "collaborations"
          t("Course Collaborations")
        when "conferences"
          t("Course Conferences")
        when "files"
          t("Course Files")
        when "grades"
          t("Course Grades")
        when "home"
          t("Course Home")
        when "modules"
          t("Course Modules")
        when "outcomes"
          t("Course Outcomes")
        when "pages"
          t("Course Pages")
        when "quizzes"
          t("Course Quizzes")
        when "roster"
          t("Course People")
        when "speed_grader"
          t("SpeedGrader")
        when "syllabus"
          t("Course Syllabus")
        when "topics"
          t("Course Discussions")
        else
          "Course #{split[0].titleize}"
        end
      elsif (match = split[1].match(/group_(\d+)/)) && (group = Group.where(:id => match[1]).first)
        case split[0]
        when "announcements"
          t("%{group_name} - Group Announcements", :group_name => group.name)
        when "calendar_feed"
          t("%{group_name} - Group Calendar", :group_name => group.name)
        when "collaborations"
          t("%{group_name} - Group Collaborations", :group_name => group.name)
        when "conferences"
          t("%{group_name} - Group Conferences", :group_name => group.name)
        when "files"
          t("%{group_name} - Group Files", :group_name => group.name)
        when "home"
          t("%{group_name} - Group Home", :group_name => group.name)
        when "pages"
          t("%{group_name} - Group Pages", :group_name => group.name)
        when "roster"
          t("%{group_name} - Group People", :group_name => group.name)
        when "topics"
          t("%{group_name} - Group Discussions", :group_name => group.name)
        else
          "#{group.name} - Group #{split[0].titleize}"
        end
      else
        self.display_name
      end
    else
      re = Regexp.new("#{self.asset_code} - ")
      self.display_name.nil? ? "" : self.display_name.gsub(re, "")
    end
  end

  def asset
    unless @asset
      return nil unless asset_code
      asset_code, general = self.asset_code.split(":").reverse
      @asset = Context.find_asset_by_asset_string(asset_code, context)
      @asset ||= (match = asset_code.match(/enrollment_(\d+)/)) && Enrollment.where(:id => match[1]).first
    end
    @asset
  end

  def asset_class_name
    name = self.asset.class.name.underscore if self.asset
    name = "Quiz" if name == "Quizzes::Quiz"
    name
  end

  def get_correct_context(context)
    if context.is_a?(UserProfile)
      context.user
    elsif context.is_a?(AssessmentQuestion)
      context.context
    else
      context
    end
  end

  def log( kontext, accessed )
    self.asset_category ||= accessed[:category]
    self.asset_group_code ||= accessed[:group_code]
    self.membership_type ||= accessed[:membership_type]
    self.context = get_correct_context(kontext)
    self.last_access = Time.now.utc
    self.display_name = self.asset_display_name
    log_action(accessed[:level])
    save
  end

  def log_action(level)
    increment(:view_score) if %w{view participate}.include?( level )
    increment(:participate_score) if %w{participate submit}.include?( level )

    if self.action_level != 'participate'
      self.action_level = (level == 'submit') ? 'participate' : level
    end
  end

  def self.infer_asset(code)
    asset_code, general = code.split(":").reverse
    asset = Context.find_asset_by_asset_string(asset_code)
    asset
  end

  # For Quizzes, we want the view score not to include the participation score
  # so it reflects the number of times a student really just browsed the quiz.
  def corrected_view_score
    deductible_points = 0

    if 'quizzes' == self.asset_group_code
      deductible_points = self.participate_score || 0
    end

    self.view_score ||= 0
    self.view_score -= deductible_points
  end

  private

  def increment(attribute)
    incremented_value = (self.send(attribute) || 0) + 1
    self.send("#{attribute}=", incremented_value)
  end

end
