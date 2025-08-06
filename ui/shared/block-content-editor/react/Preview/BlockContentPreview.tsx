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

import {Editor, Frame} from '@craftjs/core'
import {BlockContentPreviewLayout} from './BlockContentPreviewLayout'
import {BlockContentPreviewSelectorBar} from './BlockContentPreviewSelectorBar'
import {usePreviewMode} from './usePreviewMode'
import {components} from '../block-content-editor-components'
import {useGetSerializedNodes} from '../hooks/useGetSerializedNodes'

export const BlockContentPreview = () => {
  const {previewMode, setPreviewMode} = usePreviewMode()
  const data = useGetSerializedNodes()

  return (
    <BlockContentPreviewLayout
      selectorbar={
        <BlockContentPreviewSelectorBar activeTab={previewMode} onTabChange={setPreviewMode} />
      }
      preview={
        <Editor enabled={false} resolver={components}>
          <Frame data={data} />
        </Editor>
      }
    />
  )
}
