# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

#
# Client to access Microsoft's Graph API, used to administer groups and teams
# in the MicrosoftSync project (see app/models/microsoft_sync/group.rb). Make
# a new client with `GraphService.new(tenant_name)`
#
# This class is a lower-level interface, akin to what a Microsoft API gem, which
# has no knowledge of Canvas models, would provide. So, some operations will be
# used via GraphServiceHelpers, which does have knowledge of Canvas models.
#
module MicrosoftSync
  class GraphService
    attr_reader :http

    delegate :list_education_classes, :create_education_class, to: :education_classes
    delegate :update_group, :list_group_members, :list_group_owners,
             :remove_group_users_ignore_missing, :add_users_to_group_via_batch,
             :add_users_to_group_ignore_duplicates, to: :groups
    delegate :team_exists?, :create_education_class_team, to: :teams
    delegate :list_users, to: :users

    def initialize(tenant, extra_statsd_tags)
      @http = MicrosoftSync::GraphService::Http.new(tenant, extra_statsd_tags)
    end

    def education_classes
      @education_classes ||= EducationClassesEndpoints.new(http)
    end

    def groups
      @groups ||= GroupsEndpoints.new(http)
    end

    def teams
      @teams ||= TeamsEndpoints.new(http)
    end

    def users
      @users ||= UsersEndpoints.new(http)
    end
  end
end
