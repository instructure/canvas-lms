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
#

module Types
  class FileType < ApplicationObjectType
    include ApplicationHelper

    graphql_name 'File'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::ModuleItemInterface
    implements Interfaces::TimestampInterface

    # In the application_controller we use this logged_in_user to reflect either the
    # masqueraded user or the actual user. For our purposes since we only want the
    # current user, we can overwrite this here since we don't have access to the OG
    # logged_in_user method.
    def logged_in_user
      @current_user
    end

    global_id_field :id
    field :_id, ID, 'legacy canvas id', null: false, method: :id

    field :content_type, String, null: true

    field :display_name, String, null: true

    field :mime_class, String, null: true

    field :thumbnail_url, Types::UrlType, null: true
    def thumbnail_url
      return if object.locked_for?(current_user, check_policies: true)
      authenticated_thumbnail_url(object)
    end

    field :url, Types::UrlType, null: true
    def url
      return if object.locked_for?(current_user, check_policies: true)
      opts = {
        download: '1',
        download_frd: '1',
        host: context[:request].host_with_port
      }
      opts[:verifier] = object.uuid if context[:in_app]
      GraphQLHelpers::UrlHelpers.file_download_url(object, opts)
    end
  end
end
