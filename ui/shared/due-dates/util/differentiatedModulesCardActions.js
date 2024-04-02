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

import {chain, difference, find, isEmpty, union} from 'lodash'
import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'

const CardActions = {
  // -------------------
  //   Adding Assignee
  // -------------------

  handleAssigneeAdd(newAssignee, overridesFromRow, rowKey, dates) {
    this.setOverrideInitializer(rowKey, dates)

    if (newAssignee.course_section_id) {
      return this.handleSectionAdd(newAssignee, overridesFromRow)
    } else if (newAssignee.group_id) {
      return this.handleGroupAdd(newAssignee, overridesFromRow)
    } else if (newAssignee.noop_id) {
      return this.handleNoopAdd(newAssignee, overridesFromRow)
    } else {
      return this.handleStudentAdd(newAssignee, overridesFromRow)
    }
  },

  // -- Adding Sections --

  handleSectionAdd(assignee, overridesFromRow) {
    const newOverride = this.newOverrideForCard({
      course_section_id: assignee.course_section_id,
      title: assignee.name,
    })

    return union(overridesFromRow, [newOverride])
  },

  // -- Adding Groups --

  handleGroupAdd(assignee, overridesFromRow) {
    const newOverride = this.newOverrideForCard({
      group_id: assignee.group_id,
      title: assignee.name,
    })

    return union(overridesFromRow, [newOverride])
  },

  // -- Adding Students --

  handleStudentAdd(assignee, overridesFromRow) {
    const existingAdhocOverride = this.findAdhoc(overridesFromRow)

    return existingAdhocOverride
      ? this.addStudentToExistingAdhocOverride(assignee, existingAdhocOverride, overridesFromRow)
      : this.createNewAdhocOverrideForRow(assignee, overridesFromRow)
  },

  addStudentToExistingAdhocOverride(assignee, existingOverride, overridesFromRow) {
    const existingStudentIds = existingOverride.student_ids
    const newStudentIds = existingStudentIds.concat(assignee.id)

    const newOverride = {...existingOverride, student_ids: newStudentIds}
    delete newOverride.title

    return chain(overridesFromRow).difference([existingOverride]).union([newOverride]).value()
  },

  createNewAdhocOverrideForRow(assignee, overridesFromRow) {
    const freshOverride = this.newOverrideForCard({student_ids: []})
    return this.addStudentToExistingAdhocOverride(assignee, freshOverride, overridesFromRow)
  },

  // -- Adding Noop --

  handleNoopAdd(assignee, overridesFromRow) {
    const newOverride = this.newOverrideForCard({
      noop_id: assignee.noop_id,
      title: assignee.name,
    })

    if (assignee == AssignmentOverride.conditionalRelease) {
      overridesFromRow = this.removeDefaultSection(overridesFromRow)
    }

    return union(overridesFromRow, [newOverride])
  },

  // -------------------
  //  Removing Assignees
  // -------------------

  handleAssigneeRemove(assigneeToRemove, overridesFromRow) {
    if (assigneeToRemove.course_section_id) {
      return this.handleSectionRemove(assigneeToRemove, overridesFromRow)
    } else if (assigneeToRemove.group_id) {
      return this.handleGroupRemove(assigneeToRemove, overridesFromRow)
    } else if (assigneeToRemove.noop_id) {
      return this.handleNoopRemove(assigneeToRemove, overridesFromRow)
    } else {
      return this.handleStudentRemove(assigneeToRemove, overridesFromRow)
    }
  },

  handleSectionRemove(assigneeToRemove, overridesFromRow) {
    return this.removeForType('course_section_id', assigneeToRemove, overridesFromRow)
  },

  handleGroupRemove(assigneeToRemove, overridesFromRow) {
    return this.removeForType('group_id', assigneeToRemove, overridesFromRow)
  },

  handleNoopRemove(assigneeToRemove, overridesFromRow) {
    return this.removeForType('noop_id', assigneeToRemove, overridesFromRow)
  },

  removeForType(selector, assigneeToRemove, overridesFromRow) {
    const overrideToRemove = find(
      overridesFromRow,
      override => override[selector] == assigneeToRemove[selector]
    )
    return difference(overridesFromRow, [overrideToRemove])
  },

  removeDefaultSection(overridesFromRow) {
    return this.handleAssigneeRemove({course_section_id: '0'}, overridesFromRow)
  },

  handleStudentRemove(assigneeToRemove, overridesFromRow) {
    const adhocOverride = this.findAdhoc(overridesFromRow, assigneeToRemove.student_id)
    const existingStudentIds = adhocOverride.student_ids
    const newStudentIds = difference(existingStudentIds, [assigneeToRemove.student_id])

    if (isEmpty(newStudentIds)) {
      return difference(overridesFromRow, [adhocOverride])
    }

    const newOverride = {...adhocOverride, student_ids: newStudentIds}
    delete newOverride.title

    return chain(overridesFromRow).difference([adhocOverride]).union([newOverride]).value()
  },

  setOverrideInitializer(rowKey, dates) {
    if (!dates) dates = {}

    const date_attrs = {
      due_at: dates.due_at,
      due_at_overridden: !!dates.due_at,
      lock_at: dates.lock_at,
      lock_at_overridden: !!dates.lock_at,
      unlock_at: dates.unlock_at,
      unlock_at_overridden: !!dates.unlock_at,
      rowKey,
    }

    this.newOverrideForCard = function (attributes) {
      return {...date_attrs, ...attributes}
    }
  },

  // -------------------
  //      Helpers
  // -------------------

  findAdhoc(collection, idToRemove) {
    return find(collection, ov => {
      const studentIds = ov.student_ids
      return !!studentIds && (idToRemove ? studentIds.includes(idToRemove) : true)
    })
  },
}

export default CardActions
