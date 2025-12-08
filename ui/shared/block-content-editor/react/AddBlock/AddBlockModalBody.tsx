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
import {GroupedSelect, GroupedSelectItem} from '../GroupedSelect'
import {blockData} from './block-data'
import {previewFactory} from '../BlockPreview'
import {AddBlockModalBodyLayout} from './AddBlockModalBodyLayout'
import {components} from '../block-content-editor-components'

const componentsByName = Object.values(components).reduce(
  (acc, key) => {
    acc[key.name] = key
    return acc
  },
  {} as Record<string, React.FC>,
)

export const AddBlockModalBody = (props: {onBlockSelected: (block: ReactElement) => void}) => {
  const [selectedItem, setSelectedItem] = useState(blockData[0].items[0])
  const PreviewComponent = previewFactory[selectedItem.id]

  return (
    <AddBlockModalBodyLayout
      groupedSelect={
        <GroupedSelect
          data={blockData}
          onChange={(item: GroupedSelectItem) => {
            setSelectedItem(item)
            const Component = componentsByName[item.id]
            props.onBlockSelected(<Component />)
          }}
        />
      }
      preview={<PreviewComponent />}
    />
  )
}
