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

import React, {useState} from 'react'
import {AssignmentDueDate} from './AssignmentDueDate'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {nanoid} from 'nanoid'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import theme from '@instructure/canvas-theme'

const I18n = useI18nScope('discussion_create')

const DEFAULT_LIST_OPTIONS = {
  'Master Paths': [{assetCode: 'mp_option1', label: 'Master Path Option'}],
  'Course Sections': [
    {assetCode: 'sec_1', label: 'Section 1'},
    {assetCode: 'sec_2', label: 'Section 2'},
    {assetCode: 'sec_3', label: 'Section 3'},
  ],
  Students: [
    {assetCode: 'u_1', label: 'Jason'},
    {assetCode: 'u_2', label: 'Drake'},
    {assetCode: 'u_3', label: 'Caleb'},
    {assetCode: 'u_4', label: 'Aaron'},
    {assetCode: 'u_5', label: 'Chawn'},
    {assetCode: 'u_6', label: 'Omar'},
  ],
}

export const AssignmentDueDatesManager = () => {
  // This default information will be replaced by queried information
  const [assignedInfoList, setAssignedInfoList] = useState([{dueDateId: nanoid()}]) // Initialize with one object with a unique id

  const handleAssignedInfoChange = (newInfo, dueDateId) => {
    const updatedInfoList = assignedInfoList.map(info =>
      info.dueDateId === dueDateId ? {...info, ...newInfo} : info
    )
    setAssignedInfoList(updatedInfoList)
  }

  const handleAddAssignment = () => {
    setAssignedInfoList([...assignedInfoList, {dueDateId: nanoid()}]) // Add a new object with a unique id
  }

  const handleCloseAssignmentDueDate = dueDateId => () => {
    const updatedInfoList = assignedInfoList.filter(info => info.dueDateId !== dueDateId)
    setAssignedInfoList(updatedInfoList)
  }

  const getAvailableOptionsFor = dueDateId => {
    // Get all assignedList arrays, except for the one matching the given id
    const allAssignedListsExceptCurrent = assignedInfoList
      .filter(info => info.dueDateId !== dueDateId)
      .map(info => info.assignedList || [])

    // Combine all assigned lists into one array
    const allAssignedDueDateIds = [].concat(...allAssignedListsExceptCurrent)

    // Filter out options based on assigned ids
    const filteredOptions = {}
    Object.keys(DEFAULT_LIST_OPTIONS).forEach(category => {
      filteredOptions[category] = DEFAULT_LIST_OPTIONS[category].filter(option => {
        return !allAssignedDueDateIds.includes(option.assetCode)
      })
    })

    return filteredOptions
  }

  return (
    <>
      <Text size="large">{I18n.t('Assignment Settings')}</Text>
      {assignedInfoList.map((info, index) => (
        <View key={info.dueDateId}>
          <div
            style={{
              paddingTop: assignedInfoList.length === 1 ? theme.variables.spacing.medium : '0',
              borderBottom: index < assignedInfoList.length - 1 ? '1px solid #C7CDD1' : 'none',
              paddingBottom: theme.variables.spacing.medium,
            }}
          >
            {assignedInfoList.length > 1 && (
              <View display="block">
                <Flex justifyItems="space-between" alignItems="center" padding="small none small">
                  <Flex.Item shouldShrink={true} shouldGrow={true}>
                    <Text size="x-small" color="secondary">{`(${index + 1}/${
                      assignedInfoList.length
                    })`}</Text>
                  </Flex.Item>
                  <Flex.Item padding="none none none none">
                    <CloseButton
                      size="small"
                      screenReaderLabel={I18n.t('Close')}
                      onClick={handleCloseAssignmentDueDate(info.dueDateId)}
                    />
                  </Flex.Item>
                </Flex>
              </View>
            )}
            <AssignmentDueDate
              availableAssignToOptions={getAvailableOptionsFor(info.dueDateId)}
              onAssignedInfoChange={newInfo => handleAssignedInfoChange(newInfo, info.dueDateId)}
            />
          </div>
        </View>
      ))}
      <Button renderIcon={IconAddLine} onClick={handleAddAssignment}>
        {I18n.t('Add Assignment')}
      </Button>
    </>
  )
}

AssignmentDueDatesManager.propTypes = {}

AssignmentDueDatesManager.defaultProps = {}
