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

import React from 'react'
import ReactDOM from 'react-dom'
import GradebookData from './react/default_gradebook/GradebookData'
import type {GradebookOptions} from './react/default_gradebook/gradebook.d'
import ready from '@instructure/ready'

import('@canvas/context-cards/react/StudentContextCardTrigger')

ready(() => {
  const mountPoint = document.querySelector('#gradebook_app') as HTMLElement
  const gradebookMenuNode = document.querySelector(
    '[data-component="GradebookMenu"]'
  ) as HTMLSpanElement
  const actionMenuNode = document.querySelector('[data-component="ActionMenu"]') as HTMLSpanElement
  const enhancedActionMenuNode = document.querySelector(
    '[data-component="EnhancedActionMenu"]'
  ) as HTMLSpanElement
  const settingsModalButtonContainer = document.getElementById(
    'gradebook-settings-modal-button-container'
  ) as HTMLSpanElement
  const gridColorNode = document.querySelector('[data-component="GridColor"]') as HTMLSpanElement
  const viewOptionsMenuNode = document.querySelector(
    "[data-component='ViewOptionsMenu']"
  ) as HTMLSpanElement
  const applyScoreToUngradedModalNode = document.querySelector(
    '[data-component="ApplyScoreToUngradedModal"]'
  ) as HTMLSpanElement
  const gradebookGridNode = document.getElementById('gradebook_grid') as HTMLDivElement
  const gradebookSettingsModalContainer = document.querySelector(
    "[data-component='GradebookSettingsModal']"
  ) as HTMLSpanElement
  const flashMessageContainer = document.getElementById('flash_message_holder') as HTMLDivElement
  // AnonymousSpeedGraderAlert
  const anonymousSpeedGraderAlertNode = document.querySelector(
    '[data-component="AnonymousSpeedGraderAlert"]'
  ) as HTMLSpanElement

  ReactDOM.render(
    <GradebookData
      actionMenuNode={actionMenuNode}
      anonymousSpeedGraderAlertNode={anonymousSpeedGraderAlertNode}
      applyScoreToUngradedModalNode={applyScoreToUngradedModalNode}
      currentUserId={ENV.current_user_id as string}
      enhancedActionMenuNode={enhancedActionMenuNode}
      flashMessageContainer={flashMessageContainer}
      gradebookEnv={ENV.GRADEBOOK_OPTIONS as GradebookOptions}
      gradebookGridNode={gradebookGridNode}
      gradebookMenuNode={gradebookMenuNode}
      gradebookSettingsModalContainer={gradebookSettingsModalContainer}
      gridColorNode={gridColorNode}
      locale={ENV.LOCALE}
      settingsModalButtonContainer={settingsModalButtonContainer}
      viewOptionsMenuNode={viewOptionsMenuNode}
    />,
    mountPoint
  )
})
