#
# Copyright (C) 2018 - present Instructure, Inc.
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

module FeatureFlagHelper

  def mock_feature_flag(feature_flag, value, contexts=[])
    if contexts.empty?
      set_feature_flag_on_context(feature_flag, value, Account.default)

      allow_any_instance_of(Course).
        to receive(:feature_enabled?).and_call_original

      allow_any_instance_of(Course).
        to receive(:feature_enabled?).with(feature_flag.to_sym).and_return(value)
    else
      contexts.each do |context|
        set_feature_flag_on_context(feature_flag, value, context)
      end
    end
  end

  private

  def set_feature_flag_on_context(feature_flag, value, context)
    allow_any_instantiation_of(context).
      to receive(:feature_enabled?).and_call_original

    allow_any_instantiation_of(context).
      to receive(:feature_enabled?).with(feature_flag.to_sym).and_return(value)
  end
end
