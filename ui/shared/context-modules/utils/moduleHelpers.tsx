/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import React from 'react'
import {Mathml} from '@instructure/canvas-rce/es/enhance-user-content/mathml'
import ModuleFileDrop from '@canvas/context-module-file-drop/react'
import ModuleFile from '@canvas/files/backbone/models/ModuleFile'
import $, * as JQuery from 'jquery'
import {renderContextModulesPublishIcon} from './publishOneModuleHelper'
import setupContentIds from '../jquery/setupContentIds'
import {
  initPublishButton,
  overrideModel,
  setExpandAllButton,
  setExpandAllButtonVisible,
} from '../jquery/utils'
import RelockModulesDialog from '@canvas/relock-modules-dialog'

export function addModuleElement(
  data: Record<string, any>,
  $module: JQuery,
  updatePublishMenuDisabledState: (disabled: boolean) => void,
  relockModulesDialog: RelockModulesDialog,
  moduleItems: any
) {
  $module.loadingImage('remove')
  $module.attr('id', 'context_module_' + data.context_module.id)
  setupContentIds($module, data.context_module.id)

  // Set this module up with correct data attributes
  $module.data('moduleId', data.context_module.id)
  $module.data(
    'module-url',
    '/courses/' +
      data.context_module.context_id +
      '/modules/' +
      data.context_module.id +
      'items?include[]=content_details'
  )
  $module.data('workflow-state', data.context_module.workflow_state)
  if (data.context_module.workflow_state === 'unpublished') {
    $module.find('.workflow-state-action').text('Publish')
    $module
      .find('.workflow-state-icon')
      .addClass('publish-module-link')
      .removeClass('unpublish-module-link')
    $module.addClass('unpublished_module')
  }

  $('#no_context_modules_message').slideUp()
  setExpandAllButtonVisible(true)
  setExpandAllButton()
  const published = data.context_module.workflow_state === 'active'
  const $publishIcon = $module.find('.publish-icon')
  // new module, setup publish icon and other stuff
  if (!$publishIcon.data('id')) {
    const fixLink = function (locator: string, attribute: string) {
      const el = $module.find(locator)
      el.attr(attribute, (el.attr(attribute) ?? '').replace('{{ id }}', data.context_module.id))
    }
    fixLink('span.collapse_module_link', 'href')
    fixLink('span.expand_module_link', 'href')
    fixLink('.add_module_item_link', 'rel')
    fixLink('.add_module_item_link', 'rel')
    const publishData = {
      moduleType: 'module',
      id: data.context_module.id,
      courseId: data.context_module.context_id,
      published,
      publishable: true,
    }
    const view = initPublishButton($publishIcon, publishData) as {
      render: () => void
      model: ModuleFile
    }
    overrideModel(moduleItems, relockModulesDialog, view.model, view)
  }
  const isPublishing =
    document.querySelector<Element & {dataset: Record<string, string>}>(
      '#context-modules-publish-menu'
    )?.dataset['data-progress-id'] !== undefined
  updatePublishMenuDisabledState(isPublishing)
  renderContextModulesPublishIcon(
    data.context_module.context_id,
    data.context_module.id,
    published,
    isPublishing
  )
  relockModulesDialog.renderIfNeeded(data.context_module)
  $module.triggerHandler('update', data)
  const module_dnd = $module.find('.module_dnd')[0]
  if (module_dnd) {
    const contextModules = document.getElementById('context_modules')
    ReactDOM.render(
      <ModuleFileDrop
        courseId={ENV.course_id}
        moduleId={data.context_module.id}
        contextModules={contextModules}
      />,
      module_dnd
    )
  }

  const mathml = new Mathml(
    {
      new_math_equation_handling: !!ENV?.FEATURES?.new_math_equation_handling,
      explicit_latex_typesetting: !!ENV?.FEATURES?.explicit_latex_typesetting,
    },
    {locale: ENV?.LOCALE || 'en'}
  )
  if (mathml.isMathMLOnPage()) {
    if (mathml.isMathJaxLoaded()) {
      mathml.reloadElement('content')
    } else {
      mathml.loadMathJax(undefined)
    }
  }
}
