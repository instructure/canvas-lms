# frozen_string_literal: true

#
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

module NewQuizzesHelper
  def setup_new_quizzes_env(signed_launch_data, launch_url:)
    add_new_quizzes_bundle(launch_url:)
    js_env({ NEW_QUIZZES: signed_launch_data })
    add_body_class("native-new-quizzes full-width")
  end

  def add_new_quizzes_bundle(launch_url:)
    return unless @context.respond_to?(:feature_enabled?)
    return unless @context.feature_enabled?(:new_quizzes_native_experience)

    js_bundle :new_quizzes
    css_bundle :native_new_quizzes
    remote_env(new_quizzes: { launch_url: })
  end

  def self.override_item_banks_tab(tabs:, href:, context:, css_class: nil)
    item_banks_index = tabs.find_index { |t| t[:label] == "Item Banks" }
    return unless item_banks_index

    overrides = {
      id: Course::TAB_ITEM_BANKS,
      label: I18n.t("#tabs.item_banks", "Item Banks"),
      href:,
      external: false
    }
    overrides[:css_class] = css_class if css_class

    overridden_item_banks_tab = tabs[item_banks_index].except(:args).merge(overrides)
    tabs.delete_at(item_banks_index)
    tabs.insert(item_banks_index, overridden_item_banks_tab)
    overridden_item_banks_tab
  end
end
