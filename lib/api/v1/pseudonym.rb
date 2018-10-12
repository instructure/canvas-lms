#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Api::V1::Pseudonym
  include Api::V1::Json

  API_PSEUDONYM_JSON_OPTS = [:id,
                             :user_id,
                             :account_id,
                             :unique_id,
                             :sis_user_id,
                             :integration_id,
                             :authentication_provider_id,
                             :created_at].freeze

  def pseudonym_json(pseudonym, current_user, session)
    opts = API_PSEUDONYM_JSON_OPTS
    opts = opts.reject { |opt| [:sis_user_id, :integration_id].include?(opt) } unless pseudonym.account.grants_any_right?(current_user, :read_sis, :manage_sis)
    api_json(pseudonym, current_user, session, :only => opts).tap do |result|
      if pseudonym.authentication_provider
        result[:authentication_provider_type] = pseudonym.authentication_provider.auth_type
      end
    end
  end

  def pseudonyms_json(pseudonyms, current_user, session)
    ActiveRecord::Associations::Preloader.new.preload(pseudonyms, :authentication_provider)
    pseudonyms.map do |p|
      pseudonym_json(p, current_user, session)
    end
  end
end
