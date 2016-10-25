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

require [
  'jquery'
  'compiled/views/outcomes/ToolbarView'
  'compiled/views/outcomes/SidebarView'
  'compiled/views/outcomes/ContentView'
  'compiled/views/outcomes/FindDialog'
  'compiled/models/OutcomeGroup'
  'jst/outcomes/browser'
  'jst/outcomes/mainInstructions'
  'react'
  'react-dom'
  'jsx/outcomes/OutcomesActionsPopoverMenu'
], ($, ToolbarView, SidebarView, ContentView, FindDialog, OutcomeGroup, browserTemplate, instructionsTemplate, React, ReactDOM, OutcomesActionsPopoverMenu) ->

  renderInstructions = ENV.PERMISSIONS.manage_outcomes

  $el = $ '#outcomes'
  $el.html browserTemplate
    canManageOutcomes: ENV.PERMISSIONS.manage_outcomes
    canManageRubrics: ENV.PERMISSIONS.manage_rubrics
    contextUrlRoot: ENV.CONTEXT_URL_ROOT

  popoverMenu = React.createElement(OutcomesActionsPopoverMenu, {
    contextUrlRoot: ENV.CONTEXT_URL_ROOT
    permissions: ENV.PERMISSIONS
  })
  ReactDOM.render(popoverMenu, $el.find("#popoverMenu")[0])

  toolbar = new ToolbarView
    el: $el.find('.toolbar')

  sidebar = new SidebarView
    el: $el.find('.outcomes-sidebar .wrapper')
    rootOutcomeGroup: new OutcomeGroup ENV.ROOT_OUTCOME_GROUP
    selectFirstItem: !renderInstructions
  sidebar.$el.data('view', sidebar)

  content = new ContentView
    el: $el.find('.outcomes-content')
    instructionsTemplate: instructionsTemplate
    renderInstructions: renderInstructions

  # toolbar events
  toolbar.on 'goBack', sidebar.goBack
  toolbar.on 'add', sidebar.addAndSelect
  toolbar.on 'add', content.add
  toolbar.on 'find', -> sidebar.findDialog FindDialog
  # sidebar events
  sidebar.on 'select', (model) ->
    content.show(model)
  sidebar.on 'select', toolbar.resetBackButton
  # content events
  content.on 'addSuccess', sidebar.refreshSelection
  content.on 'deleteSuccess', ->
    model = sidebar.$el.find('.outcome-group.selected:last').data('view')?.model
    content.show(model)
  content.on 'move', (model, newGroup) ->
    sidebar.moveItem(model, newGroup)

  app =
    toolbar: toolbar
    sidebar: sidebar
    content: content
