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

define [
  './PopoverMenuView'
  './AddUnassignedUsersView'
  '../../InputFilterView'
  'jst/groups/manage/addUnassignedMenu'
  'jquery'
  'underscore'
  '../../../jquery/outerclick'
], (PopoverMenuView, AddUnassignedUsersView, InputFilterView, template, $, _) ->

  class AddUnassignedMenu extends PopoverMenuView

    @child 'usersView', '[data-view=users]'
    @child 'inputFilterView', '[data-view=inputFilter]'

    initialize: (options) ->
      @collection.setParam "per_page", 10
      options.usersView ?= new AddUnassignedUsersView {@collection}
      options.inputFilterView ?= new InputFilterView {@collection, setParamOnInvalid: true}
      @my = 'right-8 top-47'
      @at = 'left center'
      super

    className: 'add-unassigned-menu ui-tooltip popover right content-top horizontal'

    template: template

    events: _.extend {},
      PopoverMenuView::events,
      'click .assign-user-to-group': 'setGroup'

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user = @collection.getUser($target.data('user-id'))
      user.save({'group': @group})
      @hide()

    showBy: ($target, focus = false) ->
      @collection.reset()
      @collection.deleteParam 'search_term'
      super

    attach: ->
      @render()

    toJSON: ->
      users: @collection.toJSON()
      ENV: ENV

    focus: ->
      @inputFilterView.el.focus()

    setWidth: ->
      @$el.width 'auto'
