# frozen_string_literal: true

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

module SupportHelpers
  module PlagiarismPlatform
    class ServiceAppender < Fixer
      def initialize(email, after_time, vendor_code, product_code, service, actions)
        @vendor_code = vendor_code
        @product_code = product_code
        @service = service
        @actions = actions
        super(email, after_time)
      end

      def fix
        tool_proxies.find_each do |tp|
          next if tp.raw_data.dig("security_contract", "tool_service").blank?

          tp.raw_data["security_contract"]["tool_service"] << ims_service(@service, @actions)
          tp.save!
        end
      end

      private

      def ims_service(service, actions)
        {
          "service" => service,
          "action" => actions,
          "@type" => "RestServiceProfile"
        }
      end

      def tool_proxies
        @tool_proxies ||= begin
          product_family = Lti::ProductFamily.find_by(
            vendor_code: @vendor_code,
            product_code: @product_code
          )
          Lti::ToolProxy.where(product_family:).active
        end
      end
    end
  end
end
