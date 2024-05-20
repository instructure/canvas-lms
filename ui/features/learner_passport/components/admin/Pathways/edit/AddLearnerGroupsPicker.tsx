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

import React, {useCallback, useContext, useEffect, useState} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'

import type {LearnerGroupType} from '../../../types'
import {DataContext} from '../PathwayEditDataContext'

type LearnerGroupCardProps = {
  group: LearnerGroupType
  onRemove: (groupId: string) => void
}
const LearnerGroupCard = ({group, onRemove}: LearnerGroupCardProps) => {
  const handleRemove = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      // @ts-expect-error
      const groupId = event.currentTarget.getAttribute('data-groupid')
      onRemove(groupId)
    },
    [onRemove]
  )

  return (
    <View
      as="div"
      key={group.id}
      background="secondary"
      padding="small"
      borderWidth="small"
      borderRadius="medium"
      margin="medium 0 0 0"
    >
      <Flex as="div">
        <Flex.Item shouldGrow={true} shouldShrink={false}>
          <Text as="div" size="medium" weight="bold">
            {group.name}
          </Text>
          <View as="div" margin="x-small 0 0 0">
            <Pill margin="0 x-small 0 0">Not started</Pill>
            <Text size="small">{group.memberCount} Members</Text>
          </View>
        </Flex.Item>
        <Flex.Item shouldGrow={false}>
          <IconButton
            screenReaderLabel="remove"
            onClick={handleRemove}
            data-groupid={group.id}
            size="small"
            withBackground={false}
            withBorder={false}
          >
            <IconTrashLine />
          </IconButton>
        </Flex.Item>
      </Flex>
    </View>
  )
}

type AddLearnerGroupsPickerProps = {
  selectedLearnerGroupIds: string[]
  onChange: (selectedGroupIds: string[]) => void
}

const AddLearnerGroupsPicker = ({
  selectedLearnerGroupIds,
  onChange,
}: AddLearnerGroupsPickerProps) => {
  const {allLearnerGroups} = useContext(DataContext)
  const [currSelectedIds, setCurrSelectedIds] = useState<string[]>([...selectedLearnerGroupIds])
  const [selectionKey, setSelectionKey] = useState(selectedLearnerGroupIds.join(','))

  useEffect(() => {
    setCurrSelectedIds([...selectedLearnerGroupIds])
  }, [selectedLearnerGroupIds])

  const handleSelectGroup = useCallback(
    (_event: React.SyntheticEvent, {id}) => {
      const groupId = id
      if (!currSelectedIds.includes(groupId)) {
        const newGroups = [...currSelectedIds, groupId]
        setCurrSelectedIds(newGroups)
        setSelectionKey(newGroups.join(','))
        onChange(newGroups)
      }
    },
    [currSelectedIds, onChange]
  )

  const handleRemoveGroup = useCallback(
    (groupId: string) => {
      const newGroups = currSelectedIds.filter(id => id !== groupId)
      setCurrSelectedIds(newGroups)
      setSelectionKey(newGroups.join(','))
    },
    [currSelectedIds]
  )

  const renderGroupCard = (group: LearnerGroupType) => {
    return <LearnerGroupCard key={group.id} group={group} onRemove={handleRemoveGroup} />
  }

  const renderGroupOptions = () => {
    return allLearnerGroups
      .filter(group => !currSelectedIds.includes(group.id))
      .map(group => {
        return (
          <SimpleSelect.Option key={group.id} id={group.id} value={group.id}>
            {group.name}
          </SimpleSelect.Option>
        )
      })
  }

  return (
    <View as="div">
      <SimpleSelect
        key={selectionKey}
        renderLabel={<Text weight="normal">Select a group from Canvas to add to this pathway</Text>}
        placeholder="Select a group"
        value={undefined}
        defaultValue=""
        onChange={handleSelectGroup}
      >
        {renderGroupOptions()}
      </SimpleSelect>

      {currSelectedIds.map(groupId => {
        const group = allLearnerGroups.find(g => g.id === groupId)
        if (group) {
          return renderGroupCard(group)
        }
        return null
      })}
    </View>
  )
}

export default AddLearnerGroupsPicker
export {LearnerGroupCard}
