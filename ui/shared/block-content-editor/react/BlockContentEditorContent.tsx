/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {BlockContentEditorHandlerIntegration} from './BlockContentEditorHandlerIntegration'
import {Element, Frame} from '@craftjs/core'
import {AddBlockModalRenderer} from './AddBlock/AddBlockModalRenderer'
import {SettingsTrayRenderer} from './SettingsTray'
import {AddBlock} from './AddBlock'
import {BlockContentEditorProps} from './BlockContentEditor'
import {useGetSerializedNodes} from './hooks/useGetSerializedNodes'
import {useEditHistory} from './hooks/useEditHistory'

export const BlockContentEditorContent = (props: BlockContentEditorProps) => {
  const {isEdited} = useEditHistory()
  const editorData = useGetSerializedNodes()

  const frameData = isEdited ? editorData : (props.data ?? undefined)

  return (
    <>
      <BlockContentEditorHandlerIntegration onInit={props.onInit} />
      <AddBlockModalRenderer />
      <SettingsTrayRenderer />
      <AddBlock />
      <Frame data={frameData}>
        <Element canvas is="div" className="content-wrapper"></Element>
      </Frame>
    </>
  )
}
