# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

# Custom (teacher/admin-added) Links (aka "tabs") for Navigation
# Menus. Referenced in the contexts' tabs_available
class NavMenuLink < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable
  include CustomValidations

  self.ignored_columns += ["nav_type"]

  resolves_root_account through: :context

  belongs_to :context, polymorphic: %i[account course], separate_columns: true, optional: false

  validates :label, presence: true, length: { maximum: 255 }
  validates :url, presence: true, length: { maximum: 2048 }
  validate :url_is_valid

  # See also corresponding Postgres check constraints
  validate :at_least_one_nav_type_enabled
  validate :nav_types_match_context

  def url_is_valid
    return if url.blank? # presence validation will catch this

    if url.start_with?("/") && !url.start_with?("//")
      # Allow relative URLs (e.g., /courses/123/assignments/456)
      # Check for HTML tags before parsing to prevent XSS attacks
      if url.match?(/[<>]/)
        errors.add(:url, t("nav_menu_link.errors.url_html_tags", "is not a valid URL (cannot contain HTML tags)"))
        return
      end

      begin
        uri = URI.parse(url)
        if uri.host.present? || uri.scheme.present? || uri.path.blank?
          errors.add(:url, t("nav_menu_link.errors.url_relative_invalid", "is not a valid URL (links starting with slash must have path and no host or scheme)"))
        end
      rescue URI::Error
        errors.add(:url, t("nav_menu_link.errors.url_invalid", "is not a valid URL"))
      end
    else
      # absolute URLs -- validate and normalize as in validates_as_url
      begin
        value, = CanvasHttp.validate_url(url, allowed_schemes: %w[http https])
        self.url = value # Update with normalized URL (e.g., add http:// if missing)
      rescue CanvasHttp::Error, URI::Error, ArgumentError
        errors.add(:url, t("nav_menu_link.errors.url_invalid", "is not a valid URL"))
      end
    end
  end

  def at_least_one_nav_type_enabled
    unless course_nav || account_nav || user_nav
      errors.add(:base, t("nav_menu_link.errors.nav_type_required", "at least one nav type must be enabled"))
    end
  end

  def nav_types_match_context
    if context_type == "Course" && (account_nav || user_nav)
      errors.add(:base, t("nav_menu_link.errors.course_context_nav_only", "course-context link can only have course navigation enabled"))
    end
  end

  # See useNavMenuLinksStore.ts
  def self.as_existing_link_objects
    pluck(:id, :label, :course_nav, :account_nav, :user_nav).map do |(id, label, course_nav, account_nav, user_nav)|
      { type: "existing", id:, label:, placements: { course_nav:, account_nav:, user_nav: } }
    end
  end

  def self.sync_with_link_objects_json(context:, link_objects_json:, can_manage_links: false)
    if context.root_account.feature_enabled?(:nav_menu_links) && link_objects_json && can_manage_links
      sync_with_link_objects(context:, link_objects: JSON.parse(link_objects_json))
    end
    true
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse link_objects_json: #{e.message}")
    false
  end

  # This clears tabs caches for all contexts in root account, so this method
  # should only be used for account-context links (less frequently edited than
  # course-context links). When editing course-context links, the course-nav
  # cache is busted implicitly because the course updated_at is modified in
  # course_controller.
  def self.sync_with_link_objects(context:, link_objects:)
    link_objects = link_objects.map(&:with_indifferent_access)

    current_link_ids = Set.new(active.where(context:).pluck(:id).map(&:to_s))
    link_ids_to_remove = current_link_ids - link_objects.filter_map { |obj| obj[:id]&.to_s }

    new_links = link_objects.select { |link| link[:type] == "new" }

    transaction do
      new_links.each do |link|
        placements = link[:placements] || {}
        course_nav = placements[:course_nav] || false
        account_nav = placements[:account_nav] || false
        user_nav = placements[:user_nav] || false
        NavMenuLink.create!(url: link[:url]&.to_s, label: link[:label]&.to_s, context:, course_nav:, account_nav:, user_nav:)
      end
      where(context:, id: link_ids_to_remove.to_a).destroy_all if link_ids_to_remove.any?
    end

    if link_ids_to_remove.any? || new_links.any?
      Lti::NavigationCache.new(context.root_account).invalidate_cache_key
    end
  end
  private_class_method :sync_with_link_objects
end
