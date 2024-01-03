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
#

# NOTE: If you are looking for a way to add custom parameters or change LTI 1.1
# tool settings in bulk, there is an easier way written after this fixup. See
# DataFixup::BulkToolUpdater in instructure_misc_plugin (run
# `DataFixup::BulkToolUpdater.help` in Rails console for help)

class FixupQuizLtiRcsServiceJwtVariable < ActiveRecord::Migration[6.1]
  tag :postdeploy

  def up
    DataFixup::AddRcsServiceJwtToQuizLtiTools.delay_if_production(priority: Delayed::LOW_PRIORITY).run
  end
end
