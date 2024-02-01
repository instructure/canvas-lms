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

# asset_code is used to specify the 'asset' or idea being accessed
# asset_group_code is for the group
# so, for example, the asset could be an assignment, the group would be the assignment_group
class AssetUserAccess < ActiveRecord::Base
  extend RootAccountResolver

  belongs_to :context, polymorphic: %i[account course group user], polymorphic_prefix: true
  belongs_to :user
  has_many :page_views

  # if you add any more callbacks, be sure to update #log
  before_save :infer_defaults
  before_save :infer_root_account_id
  resolves_root_account through: ->(instance) { instance.infer_root_account_id }

  scope :for_context, ->(context) { where(context_id: context, context_type: context.class.to_s) }
  scope :for_user, ->(user) { where(user_id: user) }
  scope :participations, -> { where(action_level: "participate") }
  scope :most_recent, -> { order("updated_at DESC") }

  def infer_root_account_id(asset_for_root_account_id = nil)
    self.root_account_id ||= if context_type != "User"
                               context&.resolved_root_account_id || 0
                             elsif asset_for_root_account_id.is_a?(User)
                               # Unfillable. Point to the dummy root account with id=0.
                               0
                             else
                               asset_for_root_account_id.try(:resolved_root_account_id) ||
                                 asset_for_root_account_id.try(:root_account_id) || 0
                               # We could default `asset_for_root_account_id ||= asset`, but AUAs shouldn't
                               # ever be created outside of .log(), and calling `asset` would add a DB hit
                             end
  end

  def category
    asset_category
  end

  def infer_defaults
    self.display_name = asset_display_name
  end

  def category=(val)
    self.asset_category = val
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

    if asset.respond_to?(:title) && !asset.title.nil?
      asset.title
    elsif asset.is_a? Enrollment
      asset.user.name
    elsif asset.respond_to?(:name) && !asset.name.nil?
      asset.name
    else
      asset_code
    end
  end

  def context_code
    "#{context_type.underscore}_#{context_id}" rescue nil
  end

  def readable_name(include_group_name: true)
    if asset_code&.include?(":")
      split = asset_code.split(":")

      if split[1].match?(/course_\d+/)
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
      elsif (match = split[1].match(/group_(\d+)/)) && (group = Group.where(id: match[1]).first)
        case split[0]
        when "announcements"
          include_group_name ? t("%{group_name} - Group Announcements", group_name: group.name) : t("Group Announcements")
        when "calendar_feed"
          include_group_name ? t("%{group_name} - Group Calendar", group_name: group.name) : t("Group Calendar")
        when "collaborations"
          include_group_name ? t("%{group_name} - Group Collaborations", group_name: group.name) : t("Group Collaborations")
        when "conferences"
          include_group_name ? t("%{group_name} - Group Conferences", group_name: group.name) : t("Group Conferences")
        when "files"
          include_group_name ? t("%{group_name} - Group Files", group_name: group.name) : t("Group Files")
        when "home"
          include_group_name ? t("%{group_name} - Group Home", group_name: group.name) : t("Group Home")
        when "pages"
          include_group_name ? t("%{group_name} - Group Pages", group_name: group.name) : t("Group Pages")
        when "roster"
          include_group_name ? t("%{group_name} - Group People", group_name: group.name) : t("Group People")
        when "topics"
          include_group_name ? t("%{group_name} - Group Discussions", group_name: group.name) : t("Group Discussions")
        else
          "#{include_group_name ? "#{group.name} - " : ""}Group #{split[0].titleize}"
        end
      elsif split[1].match?(/user_\d+/)
        case split[0]
        when "files"
          t("User Files")
        else
          display_name
        end
      else
        display_name
      end
    else
      re = Regexp.new("#{asset_code} - ")
      display_name.nil? ? "" : display_name.gsub(re, "")
    end
  end

  def asset
    unless @asset
      return nil unless asset_code

      asset_code, = self.asset_code.split(":").reverse
      @asset = Context.find_asset_by_asset_string(asset_code, context)
      @asset ||= (match = asset_code.match(/enrollment_(\d+)/)) && Enrollment.where(id: match[1]).first
    end
    @asset
  end

  def asset_class_name
    name = asset.class.name.underscore if asset
    name = "Quiz" if name == "Quizzes::Quiz"
    name
  end

  def self.get_correct_context(context, accessed_asset)
    if accessed_asset[:category] == "files" && accessed_asset[:code]&.starts_with?("attachment")
      attachment_id = accessed_asset[:code].match(/\A\w+_(\d+)\z/)[1]
      asset = accessed_asset[:asset_for_root_account_id]
      return asset.context if asset.is_a?(Attachment) && asset.id == attachment_id

      Attachment.find_by(id: attachment_id)&.context
    elsif context.is_a?(UserProfile)
      context.user
    elsif context.is_a?(AssessmentQuestion)
      context.context
    else
      context
    end
  end

  def self.log(user, context, accessed_asset)
    return unless user && accessed_asset[:code]

    correct_context = get_correct_context(context, accessed_asset)
    return unless correct_context && Context::CONTEXT_TYPES.include?(correct_context.class_name.to_sym)

    GuardRail.activate(:secondary) do
      @access = AssetUserAccess.where(user:,
                                      asset_code: accessed_asset[:code],
                                      context: correct_context).first_or_initialize
    end
    accessed_asset[:level] ||= "view"
    @access.log correct_context, accessed_asset
  end

  def log(kontext, accessed)
    self.asset_category ||= accessed[:category]
    self.asset_group_code ||= accessed[:group_code]
    self.membership_type ||= accessed[:membership_type]
    self.context = kontext
    self.updated_at = self.last_access = Time.now.utc
    log_action(accessed[:level])

    # manually call callbacks to avoid transactions. this saves a BEGIN/COMMIT per request
    infer_defaults
    infer_root_account_id(accessed[:asset_for_root_account_id])

    if self.class.use_log_compaction_for_views? && eligible_for_log_path?
      # Since this is JUST a view bump, we'll write it to the
      # view log and let periodic jobs compact them later
      # (this is intentionally trading off more latency for less I/O pressure)
      AssetUserAccessLog.put_view(self)
    else
      save_without_transaction
    end
    self
  end

  def eligible_for_log_path?
    # in general we want writes to go to the table right now.
    # view count updates happen a LOT though, so if the setting is
    # configured such that we're allowed to use the log path, check
    # if this set of changes is "just" a view update.
    change_hash = changes_to_save
    updated_key_set = changes_to_save.keys.to_set
    return false unless updated_key_set.include?("view_score")
    return false unless (updated_key_set - Set.new(%w[updated_at last_access view_score])).empty?

    # ASSUMPTION: All view_score updates are a single increment.
    # If this is violated, rather than failing to capture, we should accept the
    # write through the row update for now (by returning false from here).
    view_delta = change_hash["view_score"].compact
    # ^array with old and new value, which CAN be null, hence compact
    return false if view_delta.empty?
    return (view_delta[0] - 1.0).abs < Float::EPSILON if view_delta.size == 1

    (view_delta[1] - view_delta[0]).abs == 1 # this is an increment, if true
  end

  def log_action(level)
    increment(:view_score) if %w[view participate].include?(level)
    increment(:participate_score) if %w[participate submit].include?(level)

    if action_level != "participate"
      self.action_level = (level == "submit") ? "participate" : level
    end
  end

  def self.use_log_compaction_for_views?
    view_counting_method.to_s == "log"
  end

  def self.view_counting_method
    Canvas::Plugin.find(:asset_user_access_logs).settings[:write_path]
  end

  def self.infer_asset(code)
    asset_code, = code.split(":").reverse
    Context.find_asset_by_asset_string(asset_code)
  end

  # For Quizzes, we want the view score not to include the participation score
  # so it reflects the number of times a student really just browsed the quiz.
  def corrected_view_score
    deductible_points = 0

    if self.asset_group_code == "quizzes"
      deductible_points = participate_score || 0
    end

    self.view_score ||= 0
    self.view_score -= deductible_points
  end

  # Includes both the icon name and the associated screenreader label for the icon
  ICON_MAP = {
    announcements: ["icon-announcement", t("Announcement")].freeze,
    assignments: ["icon-assignment", t("Assignment")].freeze,
    calendar: ["icon-calendar-month", t("Calendar")].freeze,
    collaborations: ["icon-document", t("Collaboration")].freeze,
    conferences: ["icon-group", t("Conference")].freeze,
    external_tools: ["icon-link", t("App")].freeze,
    files: ["icon-download", t("File")].freeze,
    grades: ["icon-gradebook", t("Grades")].freeze,
    home: ["icon-home", t("Home")].freeze,
    inbox: ["icon-message", t("Inbox")].freeze,
    modules: ["icon-module", t("Module")].freeze,
    outcomes: ["icon-outcomes", t("Outcome")].freeze,
    pages: ["icon-document", t("Page")].freeze,
    quizzes: ["icon-quiz", t("Quiz")].freeze,
    roster: ["icon-user", t("People")].freeze,
    syllabus: ["icon-syllabus", t("Syllabus")].freeze,
    topics: ["icon-discussion", t("Discussion")].freeze,
    wiki: ["icon-document", t("Page")].freeze
  }.freeze

  def icon
    ICON_MAP[asset_category.to_sym]&.[](0) || "icon-question"
  end

  def readable_category
    ICON_MAP[asset_category.to_sym]&.[](1) || ""
  end

  def self.expiration_date
    2.years.ago
  end

  DELETE_BATCH_SIZE = 10_000
  DELETE_BATCH_SLEEP = 5

  def self.delete_old_records
    loop do
      count = AssetUserAccess.connection.with_max_update_limit(DELETE_BATCH_SIZE) do
        where(last_access: ..expiration_date).limit(DELETE_BATCH_SIZE).delete_all
      end
      break if count.zero?

      sleep(DELETE_BATCH_SLEEP) # rubocop:disable Lint/NoSleep
    end
  end

  private

  def increment(attribute)
    incremented_value = (send(attribute) || 0) + 1
    send(:"#{attribute}=", incremented_value)
  end
end
