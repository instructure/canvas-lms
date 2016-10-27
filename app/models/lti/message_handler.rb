#
# Copyright (C) 2014 Instructure, Inc.
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

module Lti
  class MessageHandler < ActiveRecord::Base

    BASIC_LTI_LAUNCH_REQUEST = 'basic-lti-launch-request'.freeze
    TOOL_PROXY_REREGISTRATION_REQUEST = 'ToolProxyRegistrationRequest'.freeze

    attr_accessible :message_type, :placements, :launch_path, :capabilities, :parameters, :resource_handler, :links
    attr_readonly :created_at

    belongs_to :resource_handler, class_name: "Lti::ResourceHandler", :foreign_key => :resource_handler_id

    has_many :placements, class_name: 'Lti::ResourcePlacement', dependent: :destroy

    has_many :context_module_tags, -> { where("content_tags.tag_type='context_module' AND content_tags.workflow_state<>'deleted'").preload(context_module: :content_tags) }, as: :content, class_name: 'ContentTag'

    serialize :capabilities
    serialize :parameters

    validates_presence_of :message_type, :resource_handler, :launch_path

    scope :by_message_types, lambda { |*message_types| where(message_type: message_types) }

    scope :for_context, lambda { |context|
      tool_proxies = ToolProxy.find_active_proxies_for_context(context)
      joins(:resource_handler).where(lti_resource_handlers: { tool_proxy_id: tool_proxies })
    }

    scope :has_placements, lambda { |*placements|
      where('EXISTS (?)',
            Lti::ResourcePlacement.where(placement: placements).
                where("lti_message_handlers.id = lti_resource_placements.message_handler_id"))
    }

    def self.lti_apps_tabs(context, placements, _opts)
      apps = Lti::MessageHandler.for_context(context).
        has_placements(*placements).
        by_message_types(Lti::MessageHandler::BASIC_LTI_LAUNCH_REQUEST).to_a

      launch_path_helper = case context
                             when Course
                               :course_basic_lti_launch_request_path
                             when Account
                               :account_basic_lti_launch_request_path
                           end
      apps.sort_by(&:id).map do |app|
        args = {message_handler_id: app.id, resource_link_fragment: "nav"}
        args["#{context.class.name.downcase}_id".to_sym] = context.id
        {
          :id => app.asset_string,
          :label => app.resource_handler.name,
          :css_class => app.asset_string,
          :href => launch_path_helper,
          :visibility => nil,
          :external => true,
          :hidden => false,
          :args => args
        }
      end
    end

  end
end
