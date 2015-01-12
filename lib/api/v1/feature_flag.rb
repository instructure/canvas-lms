#
# Copyright (C) 2013 Instructure, Inc.
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

module Api::V1::FeatureFlag
  include Api::V1::Json

  def feature_json(feature, current_user, session)
    # this isn't an AR object, so api_json doesn't work
    hash = feature.as_json.slice('feature', 'applies_to', 'enable_at', 'root_opt_in', 'beta', 'development', 'release_notes_url')
    add_localized_attr(hash, feature, 'display_name')
    add_localized_attr(hash, feature, 'description')
    hash
  end

  def feature_with_flag_json(feature_flag, context, current_user, session)
    feature = Feature.definitions[feature_flag.feature]
    hash = feature_json(feature, current_user, session)
    hash['feature_flag'] = feature_flag_json(feature_flag, context, current_user, session)
    hash
  end

  def feature_flag_json(feature_flag, context, current_user, session)
    hash = if feature_flag.default?
      feature_flag.as_json.slice('feature', 'state')
    else
      keys = %w(feature context_id context_type state locking_account_id)
      api_json(feature_flag, current_user, session, only: keys)
    end
    hash['transitions'] = Feature.transitions(feature_flag.feature, current_user, context, feature_flag.state)
    hash['locked'] = feature_flag.locked?(context, current_user)
    if Account.site_admin.grants_right?(current_user, :read)
      # return 'hidden' if the feature is hidden or if this flag is the one that unhides it
      # (so removing it would re-hide the feature)
      hash['hidden'] = feature_flag.hidden? ||
          !feature_flag.default? && feature_flag.context == context && feature_flag.unhides_feature?
    end
    hash
  end

  private
  def add_localized_attr(hash, feature, attr_name)
    if attr = feature.instance_variable_get("@#{attr_name}")
      hash[attr_name] = attr.is_a?(Proc) ? attr.call : attr.to_s
    end
  end
end
