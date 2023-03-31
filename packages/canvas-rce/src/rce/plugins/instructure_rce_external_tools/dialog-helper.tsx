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

import {RceToolWrapper} from './RceToolWrapper'
import ReactDOM from 'react-dom'
import ExternalToolDialog from './components/ExternalToolDialog/ExternalToolDialog'
import React, {createRef} from 'react'

const ensureToolDialogContainerId = 'external-tool-dialog-container'

export function ensureToolDialogContainerElem(): HTMLDivElement {
  let dialogContainer = document.getElementById(ensureToolDialogContainerId) as HTMLDivElement

  if (dialogContainer === null) {
    dialogContainer = document.createElement('div')
    dialogContainer.id = ensureToolDialogContainerId
    document.body.appendChild(dialogContainer)
  }

  return dialogContainer
}

export function openToolDialogFor(toolHelper: RceToolWrapper): void {
  const dialogRef = createRef<ExternalToolDialog>()

  const env = toolHelper.env

  ReactDOM.render(
    <ExternalToolDialog
      ref={dialogRef}
      env={env}
      iframeAllowances={env.ltiIframeAllowPolicy}
      resourceSelectionUrlOverride={env.resourceSelectionUrlOverride}
    />,
    ensureToolDialogContainerElem(),
    () => {
      dialogRef.current?.open(toolHelper)
    }
  )
}
