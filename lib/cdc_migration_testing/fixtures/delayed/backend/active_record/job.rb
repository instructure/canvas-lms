# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module CdcFixtures
  def self.create_job
    # The model-generator can successfully auto-create a delayed job model.
    # However, this causes a problem when a PluginSetting model is created.
    # When a PluginSetting is created, it also creates a delayed job (the
    # inst-jobs gem does this automatically), and that job gets an id of 1
    # for some reason, even though a job with id=1 already exists. The new job
    # id doesn't get auto-incremented to 2.
    # I couldn't figure out why that was happening, so this is a workaround.
    # Manually create a delayed job here, with an id of 2, so that the
    # other job created along with the PluginSetting can use id 1.
    return Delayed::Backend::ActiveRecord::Job.new(
      id: 2,
      run_at: Time.zone.now,
    )
  end
end
