# frozen_string_literal: true

#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe NotificationPreferencesController, type: :request do
  before :once do
    user_with_pseudonym
    Notification.delete_all
    Notification.create!(name: "New Announcement", category: "Announcements")
    Notification.create!(name: "Course Started", category: "Registration")
  end

  def by_id
    @prefix = "/api/v1/users/self/communication_channels/#{@cc.id}/notification_preferences"
    @params = { user_id: "self", communication_channel_id: @cc.to_param, controller: "notification_preferences", format: "json" }
  end

  def by_address
    @prefix = "/api/v1/users/self/communication_channels/#{@cc.path_type}/#{@cc.path}/notification_preferences"
    @params = { user_id: "self", type: @cc.path_type, address: @cc.path, controller: "notification_preferences", format: "json" }
  end

  def by_category
    @prefix = "/api/v1/users/self/communication_channels/#{@cc.id}/notification_preference_categories"
    @params = { user_id: "self", communication_channel_id: @cc.to_param, controller: "notification_preferences", format: "json" }
  end

  describe "index" do
    def list_preferences
      json = api_call(:get, @prefix, @params.merge(action: "index"))
      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"].length).to eq 2
      pref = json["notification_preferences"].find { |p| p["notification"] == "new_announcement" }
      expect(pref).to eq({
                           "notification" => "new_announcement",
                           "category" => "announcements",
                           "frequency" => "daily"
                         })
      expect(@cc.notification_policies.count).to eq 2
    end

    it "lists preferences by id" do
      by_id
      list_preferences
      list_preferences
    end

    it "lists preference by address" do
      by_address
      list_preferences
      list_preferences
    end
  end

  describe "category_index" do
    it "lists categories" do
      Notification.create!(name: "Announcement Created By You", category: "Announcement Created By You")
      by_category
      json = api_call(:get, @prefix, @params.merge(action: "category_index"))
      assert_jsonapi_compliance(json, "categories")
      categories = json["categories"]
      expect(categories.length).to eq 3
      expect(categories).to eq %w[announcements registration announcement_created_by_you]
      expect(@cc.notification_policies.count).to eq 3
    end
  end

  describe "show" do
    def list_preference
      json = api_call(:get, "#{@prefix}/new_announcement", @params.merge(action: "show", notification: "new_announcement"))
      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"]).to eq [{
        "notification" => "new_announcement",
        "category" => "announcements",
        "frequency" => "daily"
      }]
      expect(@cc.notification_policies.count).to eq 1
    end

    it "lists a single preference by id" do
      by_id
      list_preference
      list_preference
    end

    it "lists a single preference by address" do
      by_address
      list_preference
      list_preference
    end
  end

  describe "update" do
    def update_preference
      # self is the only possible one
      @params.delete(:user_id)
      json = api_call(:put,
                      "#{@prefix}/new_announcement?notification_preferences[frequency]=never",
                      @params.merge(action: "update",
                                    notification: "new_announcement",
                                    notification_preferences: { "frequency" => "never" }))
      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"]).to eq [{
        "notification" => "new_announcement",
        "category" => "announcements",
        "frequency" => "never"
      }]
      expect(@cc.notification_policies.count).to eq 1
    end

    it "updates a single preference by id" do
      by_id
      update_preference
      update_preference
    end

    it "updates a single preference by address" do
      by_address
      update_preference
      update_preference
    end

    it "updates a single preference JSON API style" do
      by_address
      # self is the only possible one
      @params.delete(:user_id)
      json = api_call(:put,
                      "#{@prefix}/new_announcement",
                      @params.merge(action: "update", notification: "new_announcement"),
                      "notification_preferences" => [{ "frequency" => "never" }])
      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"]).to eq [{
        "notification" => "new_announcement",
        "category" => "announcements",
        "frequency" => "never"
      }]
      expect(@cc.notification_policies.count).to eq 1
    end
  end

  describe "update_preferences_by_category" do
    def update_preferences_by_category(category, notification = category)
      # self is the only possible one
      @params.delete(:user_id)
      json = api_call(:put,
                      "#{@prefix}/#{category}?notification_preferences[frequency]=never",
                      @params.merge(action: "update_preferences_by_category",
                                    category:,
                                    notification_preferences: { "frequency" => "never" }))
      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"]).to eq [{
        "notification" => notification,
        "category" => category,
        "frequency" => "never"
      }]
      expect(@cc.notification_policies.count).to eq 1
    end

    it "updates preferences by id and category" do
      Notification.create!(name: "Announcement Created By You", category: "Announcement Created By You")
      by_category
      update_preferences_by_category("announcement_created_by_you")
      update_preferences_by_category("announcement_created_by_you")
    end

    it "updates preferences by category JSON API style" do
      by_category
      # self is the only possible one
      @params.delete(:user_id)
      json = api_call(:put,
                      "#{@prefix}/announcements",
                      @params.merge(action: "update_preferences_by_category", category: "announcements"),
                      "notification_preferences" => [{ "frequency" => "never" }])
      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"]).to eq [{
        "notification" => "new_announcement",
        "category" => "announcements",
        "frequency" => "never"
      }]
      expect(@cc.notification_policies.count).to eq 1
    end
  end

  describe "update_all" do
    def update_preferences
      # self is the only possible one
      @params.delete(:user_id)
      json = api_call(:put,
                      "#{@prefix}?notification_preferences[new_announcement][frequency]=never&notification_preferences[course_started][frequency]=weekly",
                      @params.merge(action: "update_all",
                                    notification_preferences: { "new_announcement" => { "frequency" => "never" }, "course_started" => { "frequency" => "weekly" } }))

      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"].length).to eq 2
      pref = json["notification_preferences"].find { |p| p["notification"] == "new_announcement" }
      expect(pref).to eq({
                           "notification" => "new_announcement",
                           "category" => "announcements",
                           "frequency" => "never"
                         })

      pref = json["notification_preferences"].find { |p| p["notification"] == "course_started" }
      expect(pref).to eq({
                           "notification" => "course_started",
                           "category" => "registration",
                           "frequency" => "weekly"
                         })
      expect(@cc.notification_policies.count).to eq 2
    end

    it "updates multiple preferences by id" do
      by_id
      update_preferences
      update_preferences
    end

    it "updates multiple preferences by address" do
      by_address
      update_preferences
      update_preferences
    end

    it "updates multiple preferences JSON API style" do
      by_address
      # self is the only possible one
      @params.delete(:user_id)
      json = api_call(:put,
                      @prefix.to_s,
                      @params.merge(action: "update_all"),
                      "notification_preferences" => [{ "notification" => "new_announcement", "frequency" => "never" }, { "notification" => "course_started", "frequency" => "weekly" }])

      assert_jsonapi_compliance(json, "notification_preferences")
      expect(json["notification_preferences"].length).to eq 2
      pref = json["notification_preferences"].find { |p| p["notification"] == "new_announcement" }
      expect(pref).to eq({
                           "notification" => "new_announcement",
                           "category" => "announcements",
                           "frequency" => "never"
                         })

      pref = json["notification_preferences"].find { |p| p["notification"] == "course_started" }
      expect(pref).to eq({
                           "notification" => "course_started",
                           "category" => "registration",
                           "frequency" => "weekly"
                         })
      expect(@cc.notification_policies.count).to eq 2
    end
  end
end
