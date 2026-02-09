/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {DiscussionDueDatesContext} from '../../util/constants'
import AssignToContent from '@canvas/due-dates/react/AssignToContent'
import LoadingIndicator from '@canvas/loading-indicator'
import {View} from '@instructure/ui-view'

const DEFAULT_SECTION_ID = '0'

export const ItemAssignToTrayWrapper = () => {
  const {
    assignedInfoList,
    setAssignedInfoList,
    // @ts-expect-error TS2339 (typescriptify)
    assignmentID,
    importantDates,
    setImportantDates,
    // @ts-expect-error TS2339 (typescriptify)
    isGraded,
    // @ts-expect-error TS2339 (typescriptify)
    isCheckpoints,
    // @ts-expect-error TS2339 (typescriptify)
    postToSis,
    // @ts-expect-error TS2339 (typescriptify)
    groupCategoryId,
  } = useContext(DiscussionDueDatesContext)

  const [overrides, setOverrides] = useState([])
  const [loading, setLoading] = useState(true)

  // Make sure assignedInfoList is updated
  useEffect(() => {
    if (assignedInfoList.length > 0) {
      const newOverrides = assignedInfoList.map(convertToOverrideObject)
      // @ts-expect-error TS2345 (typescriptify)
      setOverrides(newOverrides)
    }
    setLoading(false)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Convert the assignedInfoList to the expected shape for the AssignToContent
  // @ts-expect-error TS7006 (typescriptify)
  function convertToOverrideObject(inputObj) {
    const outputObj = {
      due_at: inputObj.dueDate || null,
      lock_at: inputObj.availableUntil || null,
      unlock_at: inputObj.availableFrom || null,
      reply_to_topic_due_at: inputObj.replyToTopicDueDate || null,
      required_replies_due_at: inputObj.requiredRepliesDueDate || null,
      due_at_overridden: true,
      all_day: false,
      all_day_date: null,
      unlock_at_overridden: true,
      reply_to_topic_due_at_overridden: true,
      required_replies_due_at_overridden: true,
      lock_at_overridden: true,
      unassign_item: inputObj.unassignItem || false,
      id: inputObj.dueDateId,
      noop_id: null,
      non_collaborative: inputObj.nonCollaborative || false,
      stagedOverrideId: inputObj.stagedOverrideId || null,
      rowKey: inputObj.rowKey || null,
      replyToEntryOverrideId: inputObj.replyToEntryOverrideId || null,
      replyToTopicOverrideId: inputObj.replyToTopicOverrideId || null,
    }

    // Add context_module_id and context_module_name fields if they exist on inputObj
    if (inputObj.context_module_id) {
      // @ts-expect-error TS2339 (typescriptify)
      outputObj.context_module_id = inputObj.context_module_id
    }
    if (inputObj.context_module_name) {
      // @ts-expect-error TS2339 (typescriptify)
      outputObj.context_module_name = inputObj.context_module_name
    }

    let courseSectionId = null
    // @ts-expect-error TS7034 (typescriptify)
    const studentIds = []

    // @ts-expect-error TS7006 (typescriptify)
    inputObj.assignedList.forEach(item => {
      if (item === 'everyone') {
        courseSectionId = DEFAULT_SECTION_ID
        return
      }

      if (item === 'mastery_paths') {
        // @ts-expect-error TS2322 (typescriptify)
        outputObj.noop_id = '1'
        return
      }

      // Find the last underscore in the string and split by it
      const lastUnderscoreIndex = item.lastIndexOf('_')
      const type = item.substring(0, lastUnderscoreIndex)
      const id = item.substring(lastUnderscoreIndex + 1)

      if (type === 'course_section') {
        courseSectionId = id
      } else if (type === 'user') {
        studentIds.push(id)
      } else if (type === 'group') {
        // @ts-expect-error TS2339 (typescriptify)
        outputObj.group_id = id
        // @ts-expect-error TS2339 (typescriptify)
        outputObj.title = inputObj.title
      } else if (type === 'course') {
        // @ts-expect-error TS2339 (typescriptify)
        outputObj.course_id = id
      }
    })

    if (courseSectionId) {
      // @ts-expect-error TS2339 (typescriptify)
      outputObj.course_section_id = courseSectionId
      // @ts-expect-error TS2339 (typescriptify)
      outputObj.title = inputObj.title
    }
    if (studentIds.length > 0) {
      // @ts-expect-error TS2339,TS7005 (typescriptify)
      outputObj.student_ids = studentIds
      // @ts-expect-error TS2339,TS7006 (typescriptify)
      outputObj.students = inputObj.students?.map(student => ({
        ...student,
        id: student._id ? student._id : student.id,
      }))
    }

    return outputObj
  }

  // @ts-expect-error TS7006 (typescriptify)
  function convertToAssignedInfoListObject(inputObj) {
    const outputObj = {
      dueDateId: inputObj.rowKey || inputObj.stagedOverrideId || null,
      assignedList: [],
      replyToTopicDueDate: inputObj.reply_to_topic_due_at || null,
      requiredRepliesDueDate: inputObj.required_replies_due_at || null,
      dueDate: inputObj.due_at ? inputObj.due_at : null,
      availableFrom: inputObj.unlock_at || null,
      availableUntil: inputObj.lock_at || null,
      unassignItem: inputObj.unassign_item || false,
      context_module_id: inputObj.context_module_id || null,
      context_module_name: inputObj.context_module_name || null,
      stagedOverrideId: inputObj.stagedOverrideId || null,
      rowKey: inputObj.rowKey || null,
      replyToEntryOverrideId: inputObj.replyToEntryOverrideId || null,
      replyToTopicOverrideId: inputObj.replyToTopicOverrideId || null,
    }

    if (inputObj.noop_id === '1' || inputObj.noop_id === 1) {
      // @ts-expect-error TS2345 (typescriptify)
      outputObj.assignedList.push('mastery_paths')
    } else if (inputObj.course_section_id) {
      if (inputObj.course_section_id === '0') {
        // @ts-expect-error TS2345 (typescriptify)
        outputObj.assignedList.push('everyone')
      } else {
        // @ts-expect-error TS2345 (typescriptify)
        outputObj.assignedList.push('course_section_' + inputObj.course_section_id)
        // @ts-expect-error TS2339 (typescriptify)
        outputObj.title = inputObj.title
      }
    } else if (inputObj.student_ids) {
      // @ts-expect-error TS7006 (typescriptify)
      inputObj.student_ids.forEach(id => {
        // @ts-expect-error TS2345 (typescriptify)
        outputObj.assignedList.push('user_' + id)
      })
      // @ts-expect-error TS2339,TS7006 (typescriptify)
      outputObj.students = inputObj.students?.map(student => ({
        ...student,
        id: student._id ? student._id : student.id,
      }))
    } else if (inputObj.course_id) {
      // @ts-expect-error TS2345 (typescriptify)
      outputObj.assignedList.push('course_' + inputObj.course_id)
    } else if (inputObj.group_id) {
      // @ts-expect-error TS2345 (typescriptify)
      outputObj.assignedList.push('group_' + inputObj.group_id)
      // @ts-expect-error TS2339 (typescriptify)
      outputObj.title = inputObj.title
    }

    if (
      !inputObj.course_section_id &&
      !inputObj.course_id &&
      !inputObj.student_ids &&
      !inputObj.noop_id &&
      !inputObj.group_id
    ) {
      // @ts-expect-error TS2345 (typescriptify)
      outputObj.assignedList.push('everyone')
    }

    return outputObj
  }

  // @ts-expect-error TS7006 (typescriptify)
  const onSync = (assigneeInfoUpdateOverrides, newImportantDatesValue) => {
    if (assigneeInfoUpdateOverrides) {
      // @ts-expect-error TS7034 (typescriptify)
      const outputArray = []
      // @ts-expect-error TS7006 (typescriptify)
      assigneeInfoUpdateOverrides.forEach(inputObj => {
        const outputObj = convertToAssignedInfoListObject(inputObj)
        outputArray.push(outputObj)
      })
      // convert overrides to the expected assignedInfoList shape
      // Then Set the assignedInfoList
      // @ts-expect-error TS2554,TS7005 (typescriptify)
      setAssignedInfoList(outputArray)
    }
    setImportantDates(newImportantDatesValue)
  }

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <View as="div" maxWidth="478px">
      <AssignToContent
        onSync={onSync}
        overrides={overrides}
        // @ts-expect-error TS2322 (typescriptify)
        setOverrides={setOverrides}
        assignmentId={assignmentID}
        // @ts-expect-error TS18048 (typescriptify)
        discussionId={ENV.DISCUSSION_TOPIC.ATTRIBUTES.id}
        defaultGroupCategoryId={groupCategoryId}
        importantDates={importantDates}
        defaultSectionId={DEFAULT_SECTION_ID}
        supportDueDates={isGraded}
        type="discussion"
        isCheckpointed={isCheckpoints}
        postToSIS={postToSis}
      />
    </View>
  )
}

ItemAssignToTrayWrapper.propTypes = {}

ItemAssignToTrayWrapper.defaultProps = {}
