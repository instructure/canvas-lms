# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module K5Mode
  K5_JS_BUNDLE = [:k5_theme, nil, false].freeze

  def self.included(klass)
    super

    klass.set_callback :html_render, :before, :set_k5_mode
  end

  private

  # Setting :require_k5_theme will enable k5 theming on the page as long as user is a k5 user, even if the current
  # context is not a k5 course. Intended for use on pages that are not in a course context (like the courses index)
  def set_k5_mode(require_k5_theme: false)
    return if @set_k5_mode_run

    @set_k5_mode_run = true

    # Only students should see the details view
    @k5_details_view = @context.try(:elementary_subject_course?) && !@context.grants_right?(@current_user, :read_as_admin)
    if @context.try(:elementary_subject_course?)
      @show_left_side = !@k5_details_view
    end

    if @context.try(:elementary_enabled?) || (require_k5_theme && k5_user?)
      css_bundle :k5_theme
      css_bundle :k5_font if (@context.is_a?(Course) && !@context.account.use_classic_font_in_k5?) || (!@context.is_a?(Course) && !use_classic_font?)
      # The k5 theme needs to be loaded before other bundles to take effect
      js_bundles.unshift K5_JS_BUNDLE unless js_bundles.include? K5_JS_BUNDLE
    elsif @context.try(:feature_enabled?, :canvas_k6_theme)
      css_bundle :k6_theme
    end
  end
end
