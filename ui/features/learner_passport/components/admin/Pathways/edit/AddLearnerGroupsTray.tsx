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

import React, {useCallback, useEffect, useState} from 'react'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconTrashLine} from '@instructure/ui-icons'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'

import type {LearnerGroupType} from '../../../types'

type LearnerGroupCardProps = {
  group: LearnerGroupType
  onRemove?: (groupId: string) => void
}
const LearnerGroupCard = ({group, onRemove}: LearnerGroupCardProps) => {
  const handleRemove = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      // @ts-expect-error
      const groupId = event.currentTarget.getAttribute('data-groupid')
      onRemove?.(groupId)
    },
    [onRemove]
  )

  return (
    <View as="div" key={group.id} background="secondary" padding="medium" borderWidth="small">
      <View as="div" padding="small 0 0 0" background="secondary">
        <Flex as="div">
          <Flex.Item shouldGrow={true} shouldShrink={false}>
            <Text as="div" size="medium" weight="bold">
              {group.name}
            </Text>
            <View as="div" margin="x-small 0 0 0">
              <Text as="div" size="small">
                {group.memberCount} Members
              </Text>
            </View>
          </Flex.Item>
          {onRemove && (
            <Flex.Item shouldGrow={false}>
              <IconButton screenReaderLabel="remove" onClick={handleRemove} data-groupid={group.id}>
                <IconTrashLine />
              </IconButton>
            </Flex.Item>
          )}
        </Flex>
      </View>
    </View>
  )
}

type AddLearnerGroupsTrayProps = {
  allLearnerGroups: LearnerGroupType[]
  open: boolean
  selectedLearnerGroupIds: string[]
  onClose: () => void
  onSave: (selectedGroupIds: string[]) => void
}

const AddLearnerGroupsTray = ({
  allLearnerGroups,
  open,
  selectedLearnerGroupIds,
  onClose,
  onSave,
}: AddLearnerGroupsTrayProps) => {
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
      }
    },
    [currSelectedIds]
  )

  const handleRemoveGroup = useCallback(
    (groupId: string) => {
      const newGroups = currSelectedIds.filter(id => id !== groupId)
      setCurrSelectedIds(newGroups)
      setSelectionKey(newGroups.join(','))
    },
    [currSelectedIds]
  )

  const handleSave = useCallback(() => {
    onSave(currSelectedIds)
  }, [currSelectedIds, onSave])

  const renderGroupCard = (group: LearnerGroupType) => {
    return <LearnerGroupCard group={group} onRemove={handleRemoveGroup} />
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
    <Tray label="Learner Groups" open={open} onDismiss={onClose} size="regular" placement="end">
      <Flex as="div" direction="column" height="100vh">
        <Flex as="div" padding="small small 0 medium">
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h2" margin="0 0 small 0">
              Learner Groups
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={onClose}
            />
          </Flex.Item>
        </Flex>
        <Flex.Item shouldGrow={true} padding="medium">
          <SimpleSelect
            key={selectionKey}
            renderLabel={
              <Text weight="normal">Select a group from Canvas to add to this pathway</Text>
            }
            placeholder="Select a group"
            value={undefined}
            defaultValue=""
            onChange={handleSelectGroup}
          >
            {renderGroupOptions()}
          </SimpleSelect>
          <Flex as="div" direction="column" gap="small" margin="medium 0 0 0">
            {currSelectedIds.map(groupId => {
              const group = allLearnerGroups.find(g => g.id === groupId)
              if (group) {
                return renderGroupCard(group)
              }
              return null
            })}
          </Flex>
        </Flex.Item>
        <Flex.Item align="end" width="100%">
          <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
            <Button onClick={onClose}>Cancel</Button>
            <Button margin="0 0 0 small" onClick={handleSave}>
              Save Achievement
            </Button>
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

export default AddLearnerGroupsTray
export {LearnerGroupCard}
