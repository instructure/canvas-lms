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

import React, {useContext, useState} from 'react'
import {AssignmentDueDate} from './AssignmentDueDate'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {nanoid} from 'nanoid'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import theme from '@instructure/canvas-theme'
import {GradedDiscussionDueDatesContext} from '../../util/constants'

const I18n = useI18nScope('discussion_create')

const defaultEveryoneOption = {
  assetCode: 'everyone',
  label: 'Everyone',
}
const defaultEveryoneElseOption = {
  assetCode: 'everyone',
  label: 'Everyone else',
}

const getDefaultBaseOptions = (includeMasteryPath, everyoneOption) => {
  return includeMasteryPath
    ? [{...everyoneOption}, {assetCode: 'mastery_paths', label: 'Mastery Paths'}]
    : [{...everyoneOption}]
}

export const AssignmentDueDatesManager = () => {
  const {
    assignedInfoList,
    setAssignedInfoList,
    studentEnrollments,
    sections,
    dueDateErrorMessages,
    setDueDateErrorMessages,
  } = useContext(GradedDiscussionDueDatesContext)
  const [listOptions, setListOptions] = useState({
    '': getDefaultBaseOptions(ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED, defaultEveryoneOption),
    'Course Sections': sections.map(section => {
      return {assetCode: `course_section_${section?._id}`, label: section?.name}
    }),
    Students: studentEnrollments.map(enrollment => {
      return {assetCode: `user_${enrollment?.user?._id}`, label: enrollment?.user?.name}
    }),
  })

  const handleAssignedInfoChange = (newInfo, dueDateId) => {
    const updatedInfoList = assignedInfoList.map(info =>
      info.dueDateId === dueDateId ? {...info, ...newInfo} : info
    )
    setAssignedInfoList(updatedInfoList)
    // Remove the error message for the dueDateId if it exists
    const updatedErrorMessages = dueDateErrorMessages.filter(error => error.dueDateId !== dueDateId)
    setDueDateErrorMessages(updatedErrorMessages)
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
      .flat()

    // Filter out options based on assigned ids
    const filteredOptions = {}
    Object.keys(listOptions).forEach(category => {
      filteredOptions[category] = listOptions[category].filter(option => {
        return !allAssignedListsExceptCurrent.includes(option.assetCode)
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
              assignToErrorMessages={dueDateErrorMessages
                ?.filter(element => element.dueDateId === info.dueDateId && element.message)
                .map(element => element.message)}
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
