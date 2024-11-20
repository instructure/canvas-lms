# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::Lti::BackfillAssortedLtiRecords
  def self.run
    # these fixups all need to be run in order

    # 1. re-run: create Lti::Registrations from _deleted_ DeveloperKeys
    DataFixup::CreateLtiRegistrationsFromDeveloperKeys.run
    # 2. re-run: bind these new Registrations to their accounts
    DataFixup::Lti::BackfillLtiRegistrationAccountBindings.run
    # 3. backfill Lti::Overlays from _all_ IMS Registrations
    DataFixup::Lti::BackfillLtiOverlaysFromIMSRegistrations.run
  end
end
