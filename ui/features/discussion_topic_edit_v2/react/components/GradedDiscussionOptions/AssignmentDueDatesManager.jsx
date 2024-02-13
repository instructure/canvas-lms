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

import React, {useContext, useEffect, useState} from 'react'
import {AssignmentDueDate} from './AssignmentDueDate'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {nanoid} from 'nanoid'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import theme from '@instructure/canvas-theme'
import {
  GradedDiscussionDueDatesContext,
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  masteryPathsOption,
} from '../../util/constants'
import CoursePacingNotice from '@canvas/due-dates/react/CoursePacingNotice'

const I18n = useI18nScope('discussion_create')

const getDefaultBaseOptions = (includeMasteryPath, everyoneOption) => {
  return includeMasteryPath ? [everyoneOption, masteryPathsOption] : [everyoneOption]
}

export const AssignmentDueDatesManager = () => {
  const {
    assignedInfoList,
    setAssignedInfoList,
    studentEnrollments,
    sections,
    groups,
    gradedDiscussionRefMap,
    setGradedDiscussionRefMap,
  } = useContext(GradedDiscussionDueDatesContext)
  const [listOptions, setListOptions] = useState({
    '': getDefaultBaseOptions(ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED, defaultEveryoneOption),
    'Course Sections': sections.map(section => {
      return {assetCode: `course_section_${section?.id}`, label: section?.name}
    }),
    Students: studentEnrollments.map(user => {
      return {assetCode: `user_${user?._id}`, label: user?.name}
    }),
    Groups: groups?.map(group => {
      return {assetCode: `group_${group?._id}`, label: group?.name}
    }),
  })

  const handleAssignedInfoChange = (newInfo, dueDateId) => {
    const updatedInfoList = assignedInfoList.map(info =>
      info.dueDateId === dueDateId ? {...info, ...newInfo} : info
    )
    setAssignedInfoList(updatedInfoList)
  }

  const handleAddAssignment = () => {
    setAssignedInfoList([
      ...assignedInfoList,
      {
        dueDateId: nanoid(),
        assignedList: [],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
    ]) // Add a new object with a unique id
  }

  const handleCloseAssignmentDueDate = dueDateId => () => {
    const updatedInfoList = assignedInfoList.filter(info => info.dueDateId !== dueDateId)
    setAssignedInfoList(updatedInfoList)
    gradedDiscussionRefMap.delete(dueDateId)
    setGradedDiscussionRefMap(new Map(gradedDiscussionRefMap))
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

  useEffect(() => {
    const assignedList = assignedInfoList
      .map(info => {
        return info.assignedList || []
      })
      .flat()

    const showEveryoneElseOption = assignedList.filter(item => item !== 'everyone').length > 0

    setListOptions({
      '': getDefaultBaseOptions(
        ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED,
        showEveryoneElseOption ? defaultEveryoneElseOption : defaultEveryoneOption
      ),
      'Course Sections': sections.map(section => {
        return {assetCode: `course_section_${section?.id}`, label: section?.name}
      }),
      Students: studentEnrollments.map(user => {
        return {assetCode: `user_${user?._id}`, label: user?.name}
      }),
      Groups: groups?.map(group => {
        return {assetCode: `group_${group?._id}`, label: group?.name}
      }),
    })
  }, [assignedInfoList, groups, sections, studentEnrollments])

  const isPacedDiscussion = ENV?.DISCUSSION_TOPIC?.ATTRIBUTES?.in_paced_course

  return (
    <>
      <Text size="large">{I18n.t('Assignment Settings')}</Text>
      {isPacedDiscussion ? (
        <CoursePacingNotice courseId={ENV.COURSE_ID} />
      ) : (
        <>
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
                    <Flex
                      justifyItems="space-between"
                      alignItems="center"
                      padding="small none small"
                    >
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
                  initialAssignedInformation={info}
                  availableAssignToOptions={getAvailableOptionsFor(info.dueDateId)}
                  onAssignedInfoChange={newInfo =>
                    handleAssignedInfoChange(newInfo, info.dueDateId)
                  }
                />
              </div>
            </View>
          ))}
          <Button
            renderIcon={IconAddLine}
            onClick={handleAddAssignment}
            data-testid="add-assignment-override-seciont-btn"
          >
            {I18n.t('Add Assignment')}
          </Button>
        </>
      )}
    </>
  )
}

AssignmentDueDatesManager.propTypes = {}

AssignmentDueDatesManager.defaultProps = {}
