/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'
import createStore from '@canvas/util/createStore'
import $ from 'jquery'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromXHR'

// -------------------
//     Initialize
// -------------------

const initialStoreState = {
  students: {},
  searchedNames: {},
  currentlySearching: false,
  allStudentsFetched: false,
  requestedStudentsForCourse: false
}

const OverrideStudentStore = createStore($.extend(true, {}, initialStoreState))

// -------------------
//   Private Methods
// -------------------

function studentEnrollments(student) {
  return _.filter(
    student.enrollments,
    enrollment =>
      enrollment.type === 'StudentEnrollment' || enrollment.type === 'StudentViewEnrollment'
  )
}

function sectionIDs(enrollments) {
  return _.map(enrollments, enrollment => enrollment.course_section_id)
}

// -------------------
//      Fetching
// -------------------

// ---- by ID ----

OverrideStudentStore.fetchStudentsByID = function(givenIds) {
  if (typeof givenIds === 'undefined' || givenIds.length === 0) {
    return null
  }

  const getUsersPath = this.getContextPath() + '/users'
  $.getJSON(
    getUsersPath,
    {
      user_ids: givenIds.join(','),
      enrollment_type: 'student',
      include: ['enrollments', 'group_ids']
    },
    this._fetchStudentsByIDSuccessHandler.bind(this, {})
  )
}

OverrideStudentStore._fetchStudentsByIDSuccessHandler = function(opts, items, status, xhr) {
  this.addStudents(items)

  const links = parseLinkHeader(xhr)
  if (links.next) {
    $.getJSON(links.next, {}, this._fetchStudentsByIDSuccessHandler.bind(this, {}))
  }
}

// ---- by name ----

OverrideStudentStore.fetchStudentsByName = function(nameString) {
  if (
    $.trim(nameString) === '' ||
    this.allStudentsFetched() ||
    this.alreadySearchedForName(nameString)
  ) {
    return true
  }

  const searchUsersPath = this.getContextPath() + '/search_users'

  this.setState({
    currentlySearching: true
  })

  $.getJSON(
    searchUsersPath,
    {
      search_term: nameString,
      enrollment_type: 'student',
      include_inactive: false,
      include: ['enrollments', 'group_ids']
    },
    this._fetchStudentsByNameSuccessHandler.bind(this, {nameString}),
    this._fetchStudentsByNameErrorHandler.bind(this, {nameString})
  )
}

OverrideStudentStore.allStudentsFetched = function() {
  return this.getState().allStudentsFetched
}

OverrideStudentStore._fetchStudentsByNameSuccessHandler = function(opts, items, status, xhr) {
  this.doneSearching()
  this.markNameSearched(opts.nameString)
  this.addStudents(items)
}

OverrideStudentStore._fetchStudentsByNameErrorHandler = function(opts) {
  this.doneSearching()
}

// ---- by course ----

const PAGES_OF_STUDENTS_TO_FETCH = 4
const STUDENTS_FETCHED_PER_PAGE = 50

OverrideStudentStore.fetchStudentsForCourse = function() {
  if (this.getState().requestedStudentsForCourse) {
    return
  }
  this.setState({requestedStudentsForCourse: true})

  const path = this.getContextPath() + '/users'

  $.getJSON(
    path,
    {
      per_page: STUDENTS_FETCHED_PER_PAGE,
      enrollment_type: 'student',
      include_inactive: false,
      include: ['enrollments', 'group_ids']
    },
    this._fetchStudentsForCourseSuccessHandler.bind(this, {pageNumber: 1})
  )
}

OverrideStudentStore._fetchStudentsForCourseSuccessHandler = function(
  {pageNumber},
  items,
  status,
  xhr
) {
  this.addStudents(items)

  const links = parseLinkHeader(xhr)
  if (links.next) {
    if (pageNumber < PAGES_OF_STUDENTS_TO_FETCH) {
      $.getJSON(
        links.next,
        {},
        this._fetchStudentsForCourseSuccessHandler.bind(this, {pageNumber: pageNumber + 1})
      )
    }
  } else {
    this.setState({allStudentsFetched: true})
  }
}

// -------------------
//   Set & Get State
// -------------------

OverrideStudentStore.getStudents = function() {
  return OverrideStudentStore.getState().students
}

function nameWithSecondaryInfo(student) {
  const secondaryId = student.sis_user_id || student.email || student.login_id
  return secondaryId ? `${student.name} (${secondaryId})` : student.name
}

const normalizeName = name =>
  name
    .replace(/\p{Punctuation}/gu, '')
    .toLowerCase()
    .trim()

const addSecondaryNameInfoIfDuplicate = students => {
  const normalizedNameCounts = {}
  const nameToNormalizedName = {}
  students.forEach(student => {
    const normalizedName = normalizeName(student.name)
    nameToNormalizedName[student.name] = normalizedName
    normalizedNameCounts[normalizedName] = (normalizedNameCounts[normalizedName] || 0) + 1
  })

  return students.map(student => ({
    ...student,
    displayName:
      normalizedNameCounts[nameToNormalizedName[student.name]] > 1
        ? nameWithSecondaryInfo(student)
        : student.name
  }))
}

OverrideStudentStore.addStudents = function (newlyFetchedStudents) {
  newlyFetchedStudents.forEach(student => {
    student.enrollments = studentEnrollments(student)
    student.sections = sectionIDs(student.enrollments)
  })

  const allStudents = Object.values({
    ...this.getState().students,
    ..._.keyBy(newlyFetchedStudents, student => student.id)
  })

  // If there are duplicate student names, show secondary info
  const studentsWithSecondaryInfo = addSecondaryNameInfoIfDuplicate(allStudents)
  const studentsWithSecondaryInfoHash = _.keyBy(studentsWithSecondaryInfo, student => student.id)

  this.setState({
    students: studentsWithSecondaryInfoHash
  })
}

OverrideStudentStore.doneSearching = function() {
  this.setState({
    currentlySearching: false
  })
}

OverrideStudentStore.currentlySearching = function() {
  return this.getState().currentlySearching
}

// -------------------
//       Helpers
// -------------------

OverrideStudentStore.getContextPath = function() {
  return '/api/v1/' + DefaultUrlMixin._contextPath()
}

// test helper
OverrideStudentStore.reset = function() {
  this.setState($.extend(true, {}, initialStoreState))
}

// ----------------------
// Marking Name Searched
// ----------------------

OverrideStudentStore.alreadySearchedForName = function(name) {
  return !!this.getState().searchedNames[name]
}

OverrideStudentStore.alreadySearchingForName = function(name) {
  return _.includes(this.getState().activeNameSearches, name)
}

OverrideStudentStore.markNameSearched = function(name) {
  const searchedNames = this.getState().searchedNames
  searchedNames[name] = true
  this.setState({
    searchedNames
  })
}

export default OverrideStudentStore
