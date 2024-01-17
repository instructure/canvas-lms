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
import ready from '@instructure/ready'
import ToolbarView from './backbone/views/ToolbarView'
import SidebarView from '@canvas/outcomes/sidebar-view/backbone/views/index'
import ContentView from '@canvas/outcomes/content-view/backbone/views/index'
import FindDialog from '@canvas/outcomes/backbone/views/FindDialog'
import OutcomeGroup from '@canvas/outcomes/backbone/models/OutcomeGroup'
import browserTemplate from '@canvas/outcomes/jst/browser.handlebars'
import instructionsTemplate from './jst/mainInstructions.handlebars'
import {showImportOutcomesModal} from '@canvas/outcomes/react/ImportOutcomesModal'
import {
  showOutcomesImporter,
  showOutcomesImporterIfInProgress,
} from '@canvas/outcomes/react/OutcomesImporter'

ready(() => {
  const $el = $('#outcomes')
  $el.html(
    browserTemplate({
      canManageOutcomes: ENV.PERMISSIONS.manage_outcomes,
      canManageRubrics: ENV.PERMISSIONS.manage_rubrics,
      canImportOutcomes: ENV.PERMISSIONS.import_outcomes,
      contextUrlRoot: ENV.CONTEXT_URL_ROOT,
    })
  )

  const renderInstructions = ENV.PERMISSIONS.manage_outcomes

  const toolbar = new ToolbarView({el: $el.find('.toolbar')})

  const sidebar = new SidebarView({
    el: $el.find('.outcomes-sidebar .wrapper'),
    rootOutcomeGroup: new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP),
    selectFirstItem: !renderInstructions,
  })
  sidebar.$el.data('view', sidebar)

  const content = new ContentView({
    el: $el.find('.outcomes-content'),
    instructionsTemplate,
    renderInstructions,
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
  toolbar.on('goBack', sidebar.goBack.bind(sidebar))
  toolbar.on('add', sidebar.addAndSelect.bind(sidebar))
  toolbar.on('add', content.add.bind(content))
  toolbar.on('find', () => sidebar.findDialog(FindDialog))
  toolbar.on('import', () => showImportOutcomesModal({toolbar}))
  toolbar.on('start_sync', file =>
    showOutcomesImporter({
      file,
      disableOutcomeViews,
      resetOutcomeViews,
      mount: content.$el[0],
      contextUrlRoot: ENV.CONTEXT_URL_ROOT,
    })
  )

  if (!ENV.IMPROVED_OUTCOMES_MANAGEMENT) {
    showOutcomesImporterIfInProgress(
      {
        disableOutcomeViews,
        resetOutcomeViews,
        mount: content.$el[0],
        contextUrlRoot: ENV.CONTEXT_URL_ROOT,
      },
      ENV.current_user.id
    )
  }

  // sidebar events
  sidebar.on('select', model => content.show(model))
  sidebar.on('select', toolbar.resetBackButton.bind(toolbar))

  // content events
  content.on('addSuccess', sidebar.refreshSelection.bind(sidebar))
  content.on('deleteSuccess', () => {
    const view = sidebar.$el.find('.outcome-group.selected:last').data('view')
    const model = view && view.model
    content.show(model)
  })
  content.on('move', (model, newGroup) => sidebar.moveItem(model, newGroup))
})
