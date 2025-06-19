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

import {Editor, Frame, SerializedNodes} from '@craftjs/core'
import {AddBlock} from './AddBlock'
import {TextBlock} from './Blocks/TextBlock'
import {PageEditorContext} from './PageEditorContext'
import {AddBlockModalRenderer} from './AddBlock/AddBlockModalRenderer'
import {ImageBlock} from './Blocks/ImageBlock'
import {PageEditorLayout} from './layout/PageEditorLayout'
import {Toolbar} from './Toolbar'

export const PageEditor = (props: {
  data: SerializedNodes | null
}) => {
  return (
    <PageEditorContext>
      <PageEditorLayout
        toolbar={<Toolbar />}
        editor={
          <Editor resolver={{TextBlock, ImageBlock}}>
            <AddBlockModalRenderer />
            <AddBlock />
            <Frame data={props.data ?? undefined}>{!props.data && <article></article>}</Frame>
          </Editor>
        }
      />
    </PageEditorContext>
  )
}
