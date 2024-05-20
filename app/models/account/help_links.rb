# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class Account::HelpLinks
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def default_links(filter = true)
    defaults = [
      {
        available_to: ["student"],
        text: -> { I18n.t("#help_dialog.instructor_question", "Ask Your Instructor a Question") },
        subtext: -> { I18n.t("#help_dialog.instructor_question_sub", "Questions are submitted to your instructor") },
        url: "#teacher_feedback",
        type: "default",
        id: :instructor_question,
        is_featured: false,
        is_new: false,
        feature_headline: -> { "" }
      }.freeze,
      {
        available_to: %w[user student teacher admin observer unenrolled],
        text: -> { I18n.t("#help_dialog.search_the_canvas_guides", "Search the Canvas Guides") },
        subtext: -> { I18n.t("#help_dialog.canvas_help_sub", "Find answers to common questions") },
        url: I18n.t(:"community.guides_home"),
        type: "default",
        id: :search_the_canvas_guides,
        is_featured: true,
        is_new: false,
        feature_headline: -> { I18n.t("Little lost? Try here first!") }
      }.freeze,
      {
        available_to: %w[user student teacher admin observer unenrolled],
        text: -> { I18n.t("#help_dialog.report_problem", "Report a Problem") },
        subtext: -> { I18n.t("#help_dialog.report_problem_sub", "If Canvas misbehaves, tell us about it") },
        url: "#create_ticket",
        type: "default",
        id: :report_a_problem,
        is_featured: false,
        is_new: false,
        feature_headline: -> { "" }
      }.freeze,
      {
        available_to: %w[user student teacher admin observer unenrolled],
        text: -> { I18n.t("#help_dialog.covid", "COVID-19 Canvas Resources") },
        subtext: -> { I18n.t("#help_dialog.covid_sub", "Tips for teaching and learning online") },
        url: I18n.t(:"community.contingency_covid"),
        type: "default",
        id: :covid,
        is_new: false,
        is_featured: false,
        feature_headline: -> { "" }
      }.freeze
    ]
    filter ? filtered_links(defaults) : defaults
  end

  def default_links_hash
    @default_links_hash ||= default_links.index_by { |link| link[:id] }
  end

  # do not return the covid help link unless the featured_help_links FF is enabled
  def filtered_links(links)
    show_feedback_link = Setting.get("show_feedback_link", "false") == "true"
    links.select do |link|
      (link[:id].to_s == "covid") ? Account.site_admin.feature_enabled?(:featured_help_links) : true
    end.select do |link|
      (link[:id].to_s == "report_a_problem" || link[:id].to_s == "instructor_question") ? show_feedback_link : true
    end
  end

  def instantiate_links(links)
    instantiated = links.map do |link|
      link = link.dup
      link[:text] = link[:text].call if link[:text].respond_to?(:call)
      link[:subtext] = link[:subtext].call if link[:subtext].respond_to?(:call)
      link[:feature_headline] = link[:feature_headline].call if link[:feature_headline].respond_to?(:call)
      link = link.except(:is_featured, :is_new, :feature_headline) unless Account.site_admin.feature_enabled?(:featured_help_links)
      link
    end
    featured, not_featured = instantiated.partition { |link| link[:is_featured] }
    featured + not_featured
  end

  # take an array of links, and infer default values for links that aren't customized
  # (text is only stored in account settings if it's customized)
  def map_default_links(links)
    links.map do |link|
      default_link = link[:type] == "default" && default_links_hash[link[:id]&.to_sym]
      if default_link
        link = link.dup
        link[:text] ||= default_link[:text]
        link[:subtext] ||= default_link[:subtext]
        link[:url] ||= default_link[:url]
        link[:no_new_window] ||= default_link[:no_new_window]
        link[:is_featured] = default_link[:is_featured] unless link.key?(:is_featured)
        link[:is_new] = default_link[:is_new] unless link.key?(:is_new)
        link[:feature_headline] ||= default_link[:feature_headline]
      end
      link
    end
  end

  # complementing the above method: for each link, remove the values
  # if these match the defaults from the code. this way, other users will see localized text
  # also enforces limits on featured and new links
  def process_links_before_save(links)
    links = links.dup
    links.each do |link|
      link[:is_featured] = Canvas::Plugin.value_to_boolean(link[:is_featured])
      link[:is_new] = Canvas::Plugin.value_to_boolean(link[:is_new])
    end

    links.map do |link|
      default_link = link[:type] == "default" && default_links_hash[link[:id]&.to_sym]
      if default_link
        link.delete(:text) if link[:text] == default_link[:text].call
        link.delete(:subtext) if link[:subtext] == default_link[:subtext].call
        link.delete(:url) if link[:url] == default_link[:url]
        link.delete(:is_featured) if link[:is_featured] == default_link[:is_featured]
        link.delete(:is_new) if link[:is_new] == default_link[:is_new]
        link.delete(:feature_headline) if link[:feature_headline] == default_link[:feature_headline].try(:call)
      end
      link
    end
  end

  def self.validate_links(links)
    errors = []
    if links.count { |link| link[:is_featured] } > 1
      errors << "at most one featured link is permitted"
    elsif links.count { |link| link[:is_new] } > 1
      errors << "at most one new link is permitted"
    elsif links.any? { |link| link[:is_new] && link[:is_featured] }
      errors << "a link cannot be featured and new"
    end
    errors
  end
end
