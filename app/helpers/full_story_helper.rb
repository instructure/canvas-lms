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

module FullStoryHelper
  # the feature determines if fullstory is turned on
  # then we enabled it only for every nth login
  def fullstory_init(account, session)
    fullstory_enabled = Account.site_admin.feature_enabled?(:enable_fullstory) rescue false
    return unless fullstory_enabled
    return unless account.settings.fetch(:enable_fullstory, true)

    # this session is already hooked up
    return if session.key?(:fullstory_enabled)

    fsconfig = Canvas::DynamicSettings.find('fullstory', tree: 'config', service: 'canvas')
    rate = fsconfig[:sampling_rate].to_f
    sample = rand()
    session[:fullstory_enabled] = rate >= 0.0 && rate <= 1.0 && sample < rate
  end

  def fullstory_app_key
    Canvas::DynamicSettings.find('fullstory', tree: 'config', service: 'canvas')[:app_key] rescue nil
  end

  def fullstory_enabled_for_session?(session)
    !!session[:fullstory_enabled]
  end
end
