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
  def add_new_quizzes_bundle
    return unless @context.respond_to?(:feature_enabled?)
    return unless @context.feature_enabled?(:new_quizzes_native_experience)

    js_bundle :new_quizzes
    css_bundle :native_new_quizzes
    remote_env(new_quizzes: {
                 launch_url: Services::NewQuizzes.launch_url
               })
  end

  def self.override_item_banks_tab(tabs:, href:, context:)
    item_banks_index = tabs.find_index { |t| t[:label] == "Item Banks" }
    return unless item_banks_index

    overridden_item_banks_tab = {
      id: Course::TAB_ITEM_BANKS,
      label: I18n.t("#tabs.item_banks", "Item Banks"),
      css_class: "item_banks",
      href:,
    }

    tabs.delete_at(item_banks_index)
    tabs.insert(item_banks_index, overridden_item_banks_tab)
  end
end
