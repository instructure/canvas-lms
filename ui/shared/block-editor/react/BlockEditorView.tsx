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

import React, {useEffect, useState} from 'react'
import {Editor, Frame} from '@craftjs/core'
import {blocks} from './components/blocks'
import {
  transform,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorDataTypes,
  type BlockEditorData,
} from './utils/transformations'
import {useScope as useI18nScope} from '@canvas/i18n'

import './style.css'

const I18n = useI18nScope('block-editor')

type BlockEditorViewProps = {
  content: BlockEditorDataTypes
}

const BlockEditorView = ({content}: BlockEditorViewProps) => {
  const [data] = useState<BlockEditorData>(() => {
    if (content?.blocks) {
      return transform(content)
    }
    return {version: '0.2', blocks: undefined} as BlockEditorData
  })

  useEffect(() => {
    if (data.version !== LATEST_BLOCK_DATA_VERSION) {
      // eslint-disable-next-line no-alert
      alert(I18n.t('Unknown block data version "%{v}", mayhem may ensue', {v: data.version}))
    }
  }, [data.version])

  return (
    <Editor enabled={false} resolver={blocks}>
      <Frame data={data.blocks} />
    </Editor>
  )
}

export default BlockEditorView
