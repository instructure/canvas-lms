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

module DataFixup::UpdateDeveloperKeyScopesFromOverlay
  def self.run
    Lti::IMS::Registration.find_each do |registration|
      registration.developer_key.update!(scopes: registration.scopes - (registration.registration_overlay["disabledScopes"] || []))
    rescue ActiveRecord::RecordInvalid => e
      Sentry.with_scope do |scope|
        scope.set_tags(registration_global_id: registration.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("Datafixup.update_developer_key_scopes_from_overlay", level: :error)
      end
      Rails.logger.info("Registration #{registration.global_id} scope fixup threw #{e}")
    end
  end
end
