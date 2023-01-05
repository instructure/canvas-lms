# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::AddHeapFieldsToCommons
  HEAP_FIELDS = {
    "canvas_root_account_uuid" => "$vnd.Canvas.root_account.uuid",
    "usage_metrics_enabled" => "$com.instructure.Account.usage_metrics_enabled",
    "canvas_user_uuid" => "$vnd.instructure.User.uuid"
  }.freeze

  def self.run
    ContextExternalTool.where(name: "Canvas Commons").find_each do |commons|
      commons.custom_fields = {} if commons.custom_fields.nil?
      next if commons.custom_fields.key?(:canvas_root_account_uuid) &&
              commons.custom_fields.key?(:canvas_user_uuid) &&
              commons.custom_fields.key?(:usage_metrics_enabled)

      commons.custom_fields = commons.custom_fields.merge(HEAP_FIELDS)
      commons.save
    end
  end
end
