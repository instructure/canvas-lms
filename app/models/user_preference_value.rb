#
# Copyright (C) 2020 - present Instructure, Inc.
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

# HEY: If you were tempted to add a new thing into user preferences just add a new type here instead
# using `add_user_preference` below
# then you can write it to users with `User#set_preference`
# and retrieve the values using `User#get_preference`

class UserPreferenceValue < ActiveRecord::Base
  belongs_to :user
  serialize :value
  serialize :sub_key, JSON # i'm too lazy to force a distinction between integer and string/symbol keys

  EXTERNAL = :external.freeze

  def self.add_user_preference(key, use_sub_keys: false)
    # set use_sub_keys if we were previously storing a big ol' Hash but only getting/setting one value at a time
    # e.g. :course_grades_assignment_order is always looking at data for one course at a time
    # so rather than just storing another big serialized blob somewhere else, actually break it apart into separate rows
    @preference_settings ||= {}
    @preference_settings[key] = {use_sub_keys: use_sub_keys}
  end

  add_user_preference :closed_notifications
  add_user_preference :course_grades_assignment_order, use_sub_keys: true
  add_user_preference :course_nicknames, use_sub_keys: true
  add_user_preference :custom_colors
  add_user_preference :dashboard_positions
  add_user_preference :gradebook_column_order, use_sub_keys: true
  add_user_preference :gradebook_column_size, use_sub_keys: true
  add_user_preference :gradebook_settings, use_sub_keys: true
  add_user_preference :new_user_tutorial_statuses
  add_user_preference :selected_calendar_contexts

  def self.settings
    @preference_settings ||= {}
    @preference_settings.freeze unless @preference_settings.frozen?
    @preference_settings
  end

  module UserMethods
    # i could just stuff all this in user.rb directly but it's so full already
    def needs_preference_migration?
      self.preferences.any? do |key, value|
        UserPreferenceValue.settings[key] && value.present? && value != EXTERNAL
      end
    end

    # can remove these when all preferences have been migrated
    def migrate_preferences_if_needed
      return unless needs_preference_migration?

      reorganize_gradebook_preferences # may as well while we're at it
      UserPreferenceValue.settings.each do |key, settings|
        value = self.preferences[key]
        next unless value.present?
        next if value == EXTERNAL

        if settings[:use_sub_keys]
          value.each do |sub_key, sub_value|
            create_user_preference_value(key, sub_key, sub_value)
          end
        else
          create_user_preference_value(key, nil, value)
        end
        self.preferences[key] = EXTERNAL
      end
    end

    def get_preference(key, sub_key=nil)
      value = self.preferences[key]
      if value == EXTERNAL
        id, value = self.user_preference_values.where(:key => key, :sub_key => sub_key).pluck(:id, :value).first
        mark_preference_row(key, sub_key) if id # if we know there's a row
        value
      else
        if sub_key
          value && value[sub_key]
        else
          value
        end
      end
    end

    def set_preference(*args)
      case args.length
      when 3
        key, sub_key, value = args
      when 2
        key, value = args
        sub_key = nil
      else
        raise "wrong number of arguments"
      end
      raise "invalid key `#{key}`" unless UserPreferenceValue.settings[key]

      # don't bother trying to merge things in - just move everything over
      migrate_preferences_if_needed

      if value.present? || sub_key
        if preference_row_exists?(key, sub_key)
          update_user_preference_value(key, sub_key, value)
        else
          create_user_preference_value(key, sub_key, value)
        end
        self.preferences[key] = EXTERNAL
      else
        self.preferences[key] = value # can keep a blank value in directly here
      end
      self.changed? ? self.save : true
    end

    def clear_all_preferences_for(key)
      if UserPreferenceValue.settings[key]&.[](:use_sub_keys)
        self.user_preference_values.where(:key => key).update_all(:value => nil)
        self.preferences[key] = {}
        self.save! if self.changed?
      else
        raise "invalid key `#{key}`"
      end
    end

    def preference_row_exists?(key, sub_key)
      @existing_preference_rows&.include?([key, sub_key]) || self.user_preference_values.where(:key => key, :sub_key => sub_key).exists?
    end

    def mark_preference_row(key, sub_key)
      @existing_preference_rows ||= Set.new
      @existing_preference_rows << [key, sub_key]
    end

    def create_user_preference_value(key, sub_key, value)
      UserPreferenceValue.unique_constraint_retry do |retry_count|
        if retry_count == 0
          self.user_preference_values.create!(:key => key, :sub_key => sub_key, :value => value)
        else
          update_user_preference_value(key, sub_key, value) # may already exist
        end
      end
      mark_preference_row(key, sub_key)
    end

    def update_user_preference_value(key, sub_key, value)
      self.user_preference_values.where(:key => key, :sub_key => sub_key).update_all(:value => value)
    end

    # --- here are some hacks so we can split up the gradebook column size setting better ---
    SHARED_GRADEBOOK_COLUMNS = %w{student secondary_identifier total_grade}.freeze
    # whether we can split the column size setting into a per-course hash or in a shared one
    def shared_gradebook_column?(column)
      SHARED_GRADEBOOK_COLUMNS.include?(column)
    end

    # tl;dr will reorganize this particular preference by course so it isn't a giant blob
    # also make the other ones use global course ids
    def reorganize_gradebook_preferences
      sizes = preferences[:gradebook_column_size]
      if sizes.present? && sizes != EXTERNAL
        new_sizes = {"shared" => {}}
        id_map = {}

        sizes.each do |key, value|
          if SHARED_GRADEBOOK_COLUMNS.include?(key)
            new_sizes["shared"][key] = value
          else
            md = key.to_s.match(/(.*)_(\d+)/)
            if md
              type, id = [md[1], md[2]]
              id_map[type] ||= []
              id_map[type] << id
            end
          end
        end

        # none of these were set with any shard awareness so just go through all the possible shards and
        # even if we end up saving data for courses the user doesn't have any rights to it's better than potentially losing it
        Shard.with_each_shard(self.associated_shards) do
          # split up the other settings by course id
          if id_map["assignment"]
            Assignment.where(:id => id_map["assignment"]).pluck(:id, :context_id).each do |a_id, course_id|
              course_id = Shard.global_id_for(course_id)
              new_sizes[course_id] ||= {}
              new_sizes[course_id]["assignment_#{a_id}"] = sizes["assignment_#{a_id}"]
            end
          end
          if id_map["assignment_group"]
            AssignmentGroup.where(:id => id_map["assignment_group"]).pluck(:id, :context_id).each do |ag_id, course_id|
              course_id = Shard.global_id_for(course_id)
              new_sizes[course_id] ||= {}
              new_sizes[course_id]["assignment_group_#{ag_id}"] = sizes["assignment_group_#{ag_id}"]
            end
          end
          if id_map["custom_col"]
            CustomGradebookColumn.where(:id => id_map["custom_col"]).pluck(:id, :course_id).each do |cc_id, course_id|
              course_id = Shard.global_id_for(course_id)
              new_sizes[course_id] ||= {}
              new_sizes[course_id]["custom_col_#{cc_id}"] = sizes["custom_col_#{cc_id}"]
            end
          end
        end
        preferences[:gradebook_column_size] = new_sizes
      end

      [:gradebook_column_order, :gradebook_settings].each do |gb_pref_key|
        current_gb_prefs = preferences[gb_pref_key]
        next unless current_gb_prefs.present?
        next if current_gb_prefs == EXTERNAL
        new_gb_prefs = {}
        current_gb_prefs.each do |local_course_id, value|
          # we don't know exactly which shard it was set for, so just set it for them all associated shards
          self.associated_shards.each do |shard|
            new_gb_prefs[Shard.global_id_for(local_course_id, shard)] = value
          end
        end
        preferences[gb_pref_key] = new_gb_prefs
      end
    end
  end
end
