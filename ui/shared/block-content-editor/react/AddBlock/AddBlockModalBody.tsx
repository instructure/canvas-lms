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

import {ReactElement, useState} from 'react'
import {GroupedSelect} from '../GroupedSelect'
import {blockData, blockFactory, BlockTypes} from './block-data'
import {previewFactory} from '../BlockPreview'
import {AddBlockModalBodyLayout} from './AddBlockModalBodyLayout'

export const AddBlockModalBody = (props: {
  onBlockSelected: (block: ReactElement) => void
}) => {
  const [selectedItem, setSelectedItem] = useState<BlockTypes>(blockData[0].items[0].id)
  const PreviewComponent = previewFactory[selectedItem]

  return (
    <AddBlockModalBodyLayout
      groupedSelect={
        <GroupedSelect
          data={blockData}
          onChange={(id: BlockTypes) => {
            setSelectedItem(id)
            props.onBlockSelected(blockFactory[id]())
          }}
        />
      }
      preview={<PreviewComponent />}
    />
  )
}
