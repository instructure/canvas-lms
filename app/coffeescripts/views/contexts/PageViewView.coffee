#
# Copyright (C) 2012 Instructure, Inc.
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

define [
  'jquery'
  'underscore'
  'compiled/views/PaginatedView'
  'jst/contexts/PageView'
], ($, _, PaginatedView, pageViewTemplate) ->

  class PageViewView extends PaginatedView
    # Public: Create a new instance.
    #
    # fetchOptions - Options to be passed to @collection.fetch(). Needs to be
    #   passed for subsequent page gets (see PaginatedView).
    initialize: ({fetchOptions}) ->
      @paginationScrollContainer = @$el.parent()
      super(fetchOptions: fetchOptions)

    # Public: Append new records to the page view table.
    #
    # Returns nothing.
    render: ->
      html = _.map(@collection.models, @renderPageView).join('')
      @$el.append(html)
      super

    # Public: Return HTML for a given record.
    #
    # page_view - The page_view object to render as HTML.
    #
    # Returns an HTML string.
    renderPageView: (pageView) ->
      pageViewTemplate(pageView.toJSON())
