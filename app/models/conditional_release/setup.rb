#
# Copyright (C) 2016 Instructure, Inc.
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

require 'canvas_http'

module ConditionalRelease
  class ServiceRequestError < StandardError; end

  TOKEN_PURPOSE = "Conditional Release Service API Token"
  API_USER_NAME = "Conditional Release API"
  API_SORTABLE_NAME = "API, Conditional Release"

  class Setup
    def initialize(account_id, user_id)
      @account = Account.find(account_id)
      @root_account = @account.root_account
      @domain = @account.domain
      @user = User.find(user_id)

      # Fetch any existing API user account via unique pseudonym
      @pseudonym = Pseudonym.active.where(account_id: @root_account.id, unique_id: ConditionalRelease::Service.unique_id).first
      @api_user  = @pseudonym.user if @pseudonym.present?
      @token     = @api_user.access_tokens.find_by(purpose: TOKEN_PURPOSE) if @api_user.present?
    end

    def activate!
      return unless ConditionalRelease::Service.configured?

      if @pseudonym.blank? || @token.blank?
        @token = create_token!

        @payload = {
            external_account_id: @root_account.lti_guid.to_s,
            auth_token: @token,
            account_domains: [{ host: @domain }],
        }

        @jwt = ConditionalRelease::Service.jwt_for(@account, @user, @domain)

        self.send_later_enqueue_args(:post_to_service, max_attempts: 1)
      end

    rescue => e
      Rails.logger.error e
      undo_changes!
      raise e
    end

    private

    def create_token!
      # Creates an API user for the Conditional Release service
      # auth token is needed to make requests between
      # the service and Canvas.
      unless @pseudonym.present?
        @api_user = User.new(name: API_USER_NAME, sortable_name: API_SORTABLE_NAME)
        @api_user.workflow_state = "registered"

        @pseudonym = @api_user.pseudonyms.build(account: @root_account, unique_id: ConditionalRelease::Service.unique_id)
        @pseudonym.workflow_state = "active"
        @pseudonym.user = @api_user
        @api_user.save!

        # Make it an admin
        admin = @root_account.account_users.build
        admin.user = @api_user
        admin.save! if admin.valid?
      end

      # Generate the token to send to the Conditional Release service
      unless @token.present?
        @token = @api_user.access_tokens.build(purpose: TOKEN_PURPOSE)
        @token.save!
      end

      @token.full_token
    end

    def post_to_service
      res = CanvasHttp.post(ConditionalRelease::Service.create_account_url, {
        "Authorization" => "Bearer #{@jwt}"
      }, form_data: @payload.to_param)
      raise ConditionalRelease::ServiceRequestError, res unless res.kind_of?(Net::HTTPSuccess)
    rescue => e
      Rails.logger.error e
      undo_changes!
      raise e
    end

    def undo_changes!
      @account.disable_feature! :conditional_release
      @pseudonym.destroy! if @pseudonym
    end
  end
end
