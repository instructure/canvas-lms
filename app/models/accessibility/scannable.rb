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
      after_commit :trigger_accessibility_scan_on_create, on: :create
      after_commit :trigger_accessibility_scan_on_update, on: :update, unless: :deleted?
      after_commit :remove_accessibility_scan, on: :update, if: :deleted?
    end

    private

    def trigger_accessibility_scan_on_create
      return unless root_account.enable_content_a11y_checker?

      Accessibility::ResourceScannerService.call(resource: self)
    end

    def trigger_accessibility_scan_on_update
      return unless root_account.enable_content_a11y_checker?
      return unless scan_relevant_attribute_changed?

      Accessibility::ResourceScannerService.call(resource: self)
    end

    def scan_relevant_attribute_changed?
      case self
      when WikiPage
        saved_change_to_body? || saved_change_to_title?
      else
        true
      end
    end

    def remove_accessibility_scan
      return unless root_account.enable_content_a11y_checker?

      AccessibilityResourceScan.where(context: self).destroy_all
    end
  end
end
