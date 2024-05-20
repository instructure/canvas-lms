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

module HeapHelper
  # if he have a heap app id and the feature is enabled for the root account
  # load_help for every nth login
  def load_heap?
    return false unless find_heap_application_id && @domain_root_account&.feature_enabled?(:send_usage_metrics)

    # this session's enablement is already defined
    return session[:heap_enabled] if session.key?(:heap_enabled)

    # Yes, this says fullstory, but we had that before heap and the setting is still in consul, so let's just reuse it
    # to save a restart.
    fsconfig = DynamicSettings.find("fullstory", tree: "config", service: "canvas")
    rate = fsconfig[:sampling_rate, failsafe: 0.0].to_f
    sample = rand
    session[:heap_enabled] = rate >= 0.0 && rate <= 1.0 && sample < rate
  end

  def find_heap_application_id
    DynamicSettings.find(tree: :private)[:heap_app_id, failsafe: nil]
  end
end
