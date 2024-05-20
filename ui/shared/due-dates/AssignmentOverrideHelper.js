/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {forEach, reduce} from 'lodash'
import * as tz from '@canvas/datetime'

function addStudentID(student, collection = []) {
  return collection.concat([student.id])
}

function studentIDCollections(students) {
  const sections = {}
  const groups = {}

  forEach(students, student => {
    forEach(
      student.sections,
      sectionID => (sections[sectionID] = addStudentID(student, sections[sectionID]))
    )
    forEach(
      student.group_ids,
      groupID => (groups[groupID] = addStudentID(student, groups[groupID]))
    )
  })

  return {studentIDsInSections: sections, studentIDsInGroups: groups}
}

function studentIDsOnOverride(override, sections, groups) {
  if (override.student_ids) {
    return override.student_ids
  } else if (override.course_section_id && sections[override.course_section_id]) {
    return sections[override.course_section_id]
  } else if (override.group_id && groups[override.group_id]) {
    return groups[override.group_id]
  } else {
    return []
  }
}

function getLatestDefinedDate(newDate, existingDate) {
  if (existingDate === undefined || newDate === null) {
    return newDate
  } else if (existingDate !== null && newDate > existingDate) {
    return newDate
  } else {
    return existingDate
  }
}

function effectiveDueDatesOnOverride(
  studentIDsInSections,
  studentIDsInGroups,
  studentDueDateMap,
  override
) {
  const studentIDs = studentIDsOnOverride(override, studentIDsInSections, studentIDsInGroups)

  studentIDs.forEach(studentID => {
    const existingDate = studentDueDateMap[studentID]
    const newDate = tz.parse(override.due_at)
    studentDueDateMap[studentID] = getLatestDefinedDate(newDate, existingDate)
  })

  return studentDueDateMap
}

function effectiveDueDatesForAssignment(assignment, overrides, students) {
  const {studentIDsInSections, studentIDsInGroups} = studentIDCollections(students)

  const dates = reduce(
    overrides,
    effectiveDueDatesOnOverride.bind(this, studentIDsInSections, studentIDsInGroups),
    {}
  )

  students.forEach(student => {
    if (dates[student.id] === undefined && !assignment.only_visible_to_overrides) {
      dates[student.id] = tz.parse(assignment.due_at)
    }
  })

  return dates
}

function setStudentDisplayNames(students) {
  const normalizedNameCounts = {}
  const nameToNormalizedName = {}
  students.forEach(student => {
    const normalizedName = student.name
      .replace(/\p{Punctuation}/gu, '')
      .toLowerCase()
      .trim()
    nameToNormalizedName[student.name] = normalizedName
    normalizedNameCounts[normalizedName] = (normalizedNameCounts[normalizedName] || 0) + 1
  })

  students.forEach(student => {
    if (normalizedNameCounts[nameToNormalizedName[student.name]] > 1) {
      const secondaryId = student.sis_user_id || student.email || student.login_id
      student.displayName = secondaryId ? `${student.name} (${secondaryId})` : student.name
    } else {
      student.displayName = student.name
    }
  })
}

export default {effectiveDueDatesForAssignment, setStudentDisplayNames}
