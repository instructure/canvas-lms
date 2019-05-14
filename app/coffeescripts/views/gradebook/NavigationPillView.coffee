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

import $ from 'jquery'
import {View} from 'Backbone'

export default class NavigationPillView extends View

    events:
      'click a': 'onToggle'

    onToggle: (e) ->
      e.preventDefault()
      @setActiveTab(e.target)

    setActiveTab: (active) ->
      @$('li').removeClass('active')
      $(active).parent().addClass('active')
      @trigger('pillchange', $(active).data('id'))

    setActiveView: (viewName) ->
      @setActiveTab(@$("[data-id=#{viewName}]"))
