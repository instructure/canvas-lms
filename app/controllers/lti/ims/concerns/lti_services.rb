# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

# NOTE: All routes for controllers which include this module are expected to
# start witih /api/lti/, and will bucket throttling based on LTI Advantage
# client_id. See RequestThrottle#lti_advantage_client_id_and_cluster.
# You may need to adjust Lti::IMS::Concerns::LtiServices.lti_advantage_route? if:
# * You include this concern but don't want to bucket by client_id
# * You include this concern but have routes which don't start with /api/lti/
# * You want to bucket by client_id but don't include this concern
module Lti::IMS::Concerns
  module LtiServices
    # factories for array matchers typically returned by #scopes_matcher
    module ClassMethods
      def all_of(*items)
        ->(match_in) { items.present? && (items - match_in).blank? }
      end

      def any_of(*items)
        ->(match_in) { items.present? && items.intersect?(match_in) }
      end

      def any
        ->(_) { true }
      end

      def none
        ->(_) { false }
      end
    end

    def self.included(klass)
      super

      klass.extend(ClassMethods)
      klass.skip_before_action :load_user, :verify_authenticity_token

      klass.before_action(
        :verify_access_token,
        :verify_developer_key,
        :verify_access_scope
      )
    end

    def verify_access_token
      if (e = Lti::IMS::AdvantageAccessTokenRequestHelper.token_error(request))
        handled_error(e)
        render_error(e.api_message, e.status_code)
      elsif !access_token
        render_error("Missing access token", :unauthorized)
      end
    end

    def verify_developer_key
      unless developer_key&.active?
        render_error("Unknown or inactive Developer Key", :unauthorized)
      end
    end

    def verify_access_scope
      render_error("Insufficient permissions", :unauthorized) unless tool_permissions_granted?
    end

    def access_token
      @_access_token ||= Lti::IMS::AdvantageAccessTokenRequestHelper.token(request)
    end

    def access_token_scopes
      @_access_token_scopes ||= access_token&.claim("scopes")&.split.presence || []
    end

    def tool_permissions_granted?
      scopes_matcher.call(access_token_scopes)
    end

    def scopes_matcher
      raise "Abstract method"
    end

    def developer_key
      @_developer_key ||= access_token && begin
        DeveloperKey.find_cached(access_token.client_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    def render_error(message, status = :precondition_failed)
      error_response = {
        errors: {
          type: status,
          message:
        }
      }
      render json: error_response, status:
    end

    def handled_error(e)
      unless Rails.env.production?
        # These are all 'handled errors' so don't typically warrant logging in production envs, but in lower envs it
        # can be very handy to see exactly what went wrong. This specific log mechanism is nice, too, b/c it logs
        # backtraces from nested errors.
        logger.error(e.message)
        ErrorReport.log_exception(nil, e)
      end
    end
  end
end
