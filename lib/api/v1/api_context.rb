# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Api::V1
  class ApiContext
    attr_reader :controller, :path, :user, :session
    attr_accessor :page, :per_page

    def initialize(controller, path, user, session, options = {})
      @controller = controller
      @path = path
      @user = user
      @session = session
      @page = options.fetch(:page, 1)
      @per_page = options[:per_page]
    end

    def paginate(collection)
      Api.paginate(collection, controller, path, pagination_options)
    end

    private
    def pagination_options
      if @per_page
        { :page => @page , :per_page => @per_page}
      else
        { :page => @page }
      end
    end
  end
end
