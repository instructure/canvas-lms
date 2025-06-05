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

import {useEffect, useState} from 'react'
import {BlockData, BlockTypes} from '../AddBlock/block-data'
import {GroupedSelectLayout} from './GroupedSelectLayout'
import {GroupedSelectEntry} from './GroupedSelectEntry'

export const GroupedSelect = (props: {
  data: BlockData[]
  onChange: (id: BlockTypes) => void
}) => {
  const [selectedGroup, setSelectedGroup] = useState<string>(props.data[0].groupName)
  const [selectedItem, setSelectedItem] = useState<BlockTypes>(props.data[0].items[0].id)

  const handleItemClick = (id: BlockTypes) => {
    setSelectedItem(id)
    props.onChange(id)
  }

  useEffect(() => {
    props.onChange(selectedItem)
  }, [])

  return (
    <GroupedSelectLayout
      groups={props.data.map(group => (
        <GroupedSelectEntry
          key={group.groupName}
          variant="group"
          title={group.groupName}
          active={group.groupName === selectedGroup}
          onClick={() => {
            setSelectedGroup(group.groupName)
            handleItemClick(group.items[0].id)
          }}
        />
      ))}
      items={props.data
        .find(group => group.groupName === selectedGroup)
        ?.items.map(item => (
          <GroupedSelectEntry
            key={item.itemName}
            variant="item"
            title={item.itemName}
            active={selectedItem === item.id}
            onClick={() => {
              handleItemClick(item.id)
            }}
          />
        ))}
    />
  )
}
