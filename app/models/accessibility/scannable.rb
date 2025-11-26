# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module Accessibility
  module Scannable
    extend ActiveSupport::Concern

    included do
      before_save :capture_content_changes

      after_commit :trigger_accessibility_scan_on_create,
                   on: :create,
                   if: :should_run_accessibility_scan?

      after_commit :trigger_accessibility_scan_on_update,
                   on: :update,
                   if: :should_run_accessibility_scan?

      after_commit :remove_accessibility_scan,
                   on: :update,
                   if: :deleted?

      attr_accessor :skip_accessibility_scan
    end

    def save_without_accessibility_scan
      @skip_accessibility_scan = true
      save
    ensure
      @skip_accessibility_scan = false
    end

    def save_without_accessibility_scan!
      @skip_accessibility_scan = true
      save!
    ensure
      @skip_accessibility_scan = false
    end

    private

    def capture_content_changes
      # Capture content changes before they're lost by subsequent touch operations.
      # Rails' dirty tracking gets cleared when associations touch the parent record,
      # so we store the change state here to check later in after_commit.
      @content_changed = if a11y_scannable_attributes.present?
                           a11y_scannable_attributes.any? { |attr| send("#{attr}_changed?") }
                         else
                           false
                         end
    end

    def should_run_accessibility_scan?
      a11y_checker_enabled? &&
        !deleted? &&
        !skip_accessibility_scan &&
        !excluded_from_accessibility_scan? &&
        any_completed_accessibility_scan?
    end

    def a11y_checker_enabled?
      context.is_a?(Course) && context.a11y_checker_enabled?
    end

    def any_completed_accessibility_scan?
      Accessibility::CourseScanService.last_accessibility_course_scan(course)&.completed? || false
    end

    def trigger_accessibility_scan_on_create
      Accessibility::ResourceScannerService.call(resource: self)
    end

    def trigger_accessibility_scan_on_update
      return unless @content_changed.present?

      Accessibility::ResourceScannerService.call(resource: self)
    end

    def remove_accessibility_scan
      AccessibilityResourceScan.where(context: self).destroy_all
    end

    def a11y_scannable_attributes
      raise NotImplementedError, "#{self.class.name} must implement #a11y_scannable_attributes"
    end

    def excluded_from_accessibility_scan?
      false
    end
  end
end
