#
# Copyright (C) 2016 - present Instructure, Inc.
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

module SupportHelpers
  class PlagiarismPlatformController < ApplicationController
    include SupportHelpers::ControllerHelpers

    before_action :require_site_admin

    protect_from_forgery with: :exception

    # @API Add Tool Service
    # @internal
    # Add a service to the security contracts of all tool proxies
    # with the provided vendor/product codes.
    #
    # Example Request:
    # http://canvas.docker/api/v1/support_helpers/plagiarism_platform/add_service?
    #   product_code=similarity%20detection%20reference%20tool
    #   &vendor_code=Instructure.com
    #   &service=vnd.Canvas.webhooksSubscription
    #   &actions[]=POST&actions[]=GET
    #
    # @argument product_code [String]
    #   The product code of the tool proxies to modify
    # @argument vendor_code [String]
    #   The vendor code of the tool proxies to modify
    # @argument service [String]
    #   The case-sensitive service name
    # @argument actions [Array]
    #   The actions ('GET', 'POST', 'GET', 'PUT', or 'Delete')
    #   the tool should be authorized to use with the
    #   service
    def add_service
      run_fixer(
        SupportHelpers::PlagiarismPlatform::ServiceAppender,
        vendor_code,
        product_code,
        service_name,
        service_actions
      )
    end

    # @API Resubmit All Submissions to Tool
    # @internal
    # Resends a 'plagiarism_resubmit' webhook for each submission
    # in the specified assignment
    #
    # Example Request:
    # http://canvas.docker/api/v1/support_helpers/plagiarism_platform/
    #   resubmit_for_assignment/85
    #
    # @argument assignment_id [Integer]
    #   The assignment ID
    def resubmit_for_assignment
      run_fixer(
        SupportHelpers::AssignmentResubmission,
        Assignment.find(params[:assignment_id])
      )
    end

    private

    def product_code
      params.require(:product_code)
    end

    def vendor_code
      params.require(:vendor_code)
    end

    def service_name
      params.require(:service)
    end

    def service_actions
      @service_actions ||= params.require(:actions).map(&:upcase)
    end
  end
end
