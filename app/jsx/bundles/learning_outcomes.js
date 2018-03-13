/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import ToolbarView from 'compiled/views/outcomes/ToolbarView'
import SidebarView from 'compiled/views/outcomes/SidebarView'
import ContentView from 'compiled/views/outcomes/ContentView'
import FindDialog from 'compiled/views/outcomes/FindDialog'
import OutcomeGroup from 'compiled/models/OutcomeGroup'
import browserTemplate from 'jst/outcomes/browser'
import instructionsTemplate from 'jst/outcomes/mainInstructions'
import React from 'react'
import ReactDOM from 'react-dom'
import {showImportOutcomesModal} from '../outcomes/ImportOutcomesModal'
import {showOutcomesImporter, showOutcomesImporterIfInProgress} from '../outcomes/OutcomesImporter'

const renderInstructions = ENV.PERMISSIONS.manage_outcomes

const $el = $('#outcomes')
$el.html(browserTemplate({
  canManageOutcomes: ENV.PERMISSIONS.manage_outcomes,
  canManageRubrics: ENV.PERMISSIONS.manage_rubrics,
  contextUrlRoot: ENV.CONTEXT_URL_ROOT
}))

export const toolbar = new ToolbarView({el: $el.find('.toolbar')})

export const sidebar = new SidebarView({
  el: $el.find('.outcomes-sidebar .wrapper'),
  rootOutcomeGroup: new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP),
  selectFirstItem: !renderInstructions
})
sidebar.$el.data('view', sidebar)

export const content = new ContentView({
  el: $el.find('.outcomes-content'),
  instructionsTemplate,
  renderInstructions
})

// events for Outcome sync
const disableOutcomeViews = () => {
  sidebar.$sidebar.hide()
  toolbar.disable()
}

const resetOutcomeViews = () => {
  toolbar.enable()
  sidebar.resetSidebar()
  content.resetContent()
  sidebar.$sidebar.show()
}

// toolbar events
toolbar.on('goBack', sidebar.goBack)
toolbar.on('add', sidebar.addAndSelect)
toolbar.on('add', content.add)
toolbar.on('find', () => sidebar.findDialog(FindDialog))
toolbar.on('import', () => showImportOutcomesModal({toolbar}))
toolbar.on('start_sync', (file) => showOutcomesImporter({
  file,
  disableOutcomeViews,
  resetOutcomeViews,
  mount: content.$el[0],
  contextUrlRoot: ENV.CONTEXT_URL_ROOT
}))

showOutcomesImporterIfInProgress({
  disableOutcomeViews,
  resetOutcomeViews,
  mount: content.$el[0],
  contextUrlRoot: ENV.CONTEXT_URL_ROOT
}, ENV.current_user.id)

// sidebar events
sidebar.on('select', model => content.show(model))
sidebar.on('select', toolbar.resetBackButton)

// content events
content.on('addSuccess', sidebar.refreshSelection)
content.on('deleteSuccess', () => {
  const view = sidebar.$el.find('.outcome-group.selected:last').data('view')
  const model = view && view.model
  content.show(model)
})
content.on('move', (model, newGroup) => sidebar.moveItem(model, newGroup))
