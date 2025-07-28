/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {type GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import ready from '@instructure/ready'
import {BlockEditorView, type BlockEditorDataTypes} from '@canvas/block-editor'

declare const ENV: GlobalEnv & {
  block_editor_attributes: string
}

ready(() => {
  document.documentElement.setAttribute('style', 'overflow: auto;width:100%;height:100%;')

  const block_editor_attributes: BlockEditorDataTypes = JSON.parse(ENV.block_editor_attributes)

  ReactDOM.render(
    <BlockEditorView content={block_editor_attributes} />,
    document.getElementById('block_editor_viewer_container') as HTMLElement,
  )
})
