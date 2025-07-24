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

import {Editor, Element, Frame} from '@craftjs/core'
import {AddBlock} from './AddBlock'
import {TextBlock} from './Blocks/TextBlock'
import {AddBlockModalRenderer} from './AddBlock/AddBlockModalRenderer'
import {ImageBlock} from './Blocks/ImageBlock'
import {useBlockContentEditorIntegration} from './hooks/useBlockContentEditorIntegration'
import {Prettify} from './utilities/Prettify'
import {BlockContentEditorProps} from './BlockContentEditor'

export type BlockContentEditorWrapperProps = Prettify<
  Omit<BlockContentEditorProps, 'mode'> & {
    isEditMode: boolean
  }
>

export const BlockContentEditorWrapper = (props: BlockContentEditorWrapperProps) => {
  const onNodesChange = useBlockContentEditorIntegration(props.onInit)
  return (
    <Editor
      enabled={props.isEditMode}
      resolver={{TextBlock, ImageBlock}}
      onNodesChange={onNodesChange}
    >
      <AddBlockModalRenderer />
      <AddBlock />
      <Frame data={props.data ?? undefined}>
        <Element is="div"></Element>
      </Frame>
    </Editor>
  )
}
