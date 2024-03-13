/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import tinymce from 'tinymce'

import React from 'react'
import ReactDOM from 'react-dom'
import {
  RceToolWrapper,
  buildToolMenuItems,
  ExternalToolMenuItem,
  externalToolsForToolbar,
} from './RceToolWrapper'
import formatMessage from '../../../format-message'
import {ExternalToolSelectionDialog} from './components/ExternalToolSelectionDialog/ExternalToolSelectionDialog'
import {ensureToolDialogContainerElem} from './dialog-helper'
import {ExternalToolsEditor, externalToolsEnvFor} from './ExternalToolsEnv'

// Register plugin
tinymce.PluginManager.add('instructure_rce_external_tools', initExternalToolsLocalPlugin)

/**
 * This plugin adds the "Apps" toolbar button and the "Apps" menu item. It is a rewrite of 'instructure_external_tools'
 * to live fully in the canvas-rce package. It supports running in an iframe as part of an LTI tool, such as
 * new quizzes.
 *
 * @param editor
 */
export function initExternalToolsLocalPlugin(editor: ExternalToolsEditor) {
  if (RceToolWrapper.forEditorEnv(externalToolsEnvFor(editor)).length === 0) {
    return
  }

  registerFavoriteAppsToolbarButtons(editor)

  registerAppsToolbarButton(editor)

  registerAppsMenu(editor)
}

/**
 * Add the "Apps" toolbar button with "View all" and MRU buttons
 */
function registerAppsMenu(editor: ExternalToolsEditor) {
  editor.ui.registry.addNestedMenuItem('lti_tools_menuitem', {
    text: formatMessage('Apps'),
    icon: 'lti',
    getSubmenuItems: () => {
      const availableTools = RceToolWrapper.forEditorEnv(externalToolsEnvFor(editor))
      const toolMenuItems = buildToolMenuItems(availableTools, makeViewAllItem(editor))

      return toolMenuItems
    },
  })
}

/**
 * Registers toolbar buttons for favorite apps
 */
function registerFavoriteAppsToolbarButtons(editor: ExternalToolsEditor) {
  const allTools = RceToolWrapper.forEditorEnv(externalToolsEnvFor(editor))
  externalToolsForToolbar(allTools).forEach(toolInfo =>
    editor.ui.registry.addButton(
      `instructure_external_button_${toolInfo.id}`,
      toolInfo.asToolbarButton()
    )
  )
}

function registerAppsToolbarButton(editor: ExternalToolsEditor) {
  const tooltip = formatMessage('Apps')
  editor.ui.registry.addMenuButton('lti_mru_button', {
    tooltip,
    icon: 'lti',
    fetch: callback => {
      const availableTools = RceToolWrapper.forEditorEnv(externalToolsEnvFor(editor))
      const toolMenuItems = buildToolMenuItems(availableTools, makeViewAllItem(editor))
      callback(toolMenuItems)
    },
    onSetup(_api) {
      return () => undefined
    },
  })
}

function openToolSelectionDialog(editor: ExternalToolsEditor) {
  const availableTools = RceToolWrapper.forEditorEnv(externalToolsEnvFor(editor))

  const container = ensureToolDialogContainerElem()

  const handleDismiss = () => {
    ReactDOM.unmountComponentAtNode(container)
    editor.focus()
  }

  ReactDOM.render(
    <ExternalToolSelectionDialog onDismiss={handleDismiss} ltiButtons={availableTools} />,
    ensureToolDialogContainerElem()
  )
}

function makeViewAllItem(editor: ExternalToolsEditor): ExternalToolMenuItem {
  return {
    type: 'menuitem',
    text: formatMessage('View All'),
    onAction() {
      openToolSelectionDialog(editor)
    },
  }
}
