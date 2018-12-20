/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {TeacherViewContextDefaults} from './components/TeacherViewContext'
import {wait} from 'react-testing-library'

// because our version of jsdom doesn't support elt.closest('a') yet. Should soon.
export function closest(el, selector) {
  while (el && !el.matches(selector)) {
    el = el.parentElement
  }
  return el
}

export function findInputForLabel(labelChild, container) {
  const label = closest(labelChild, 'label')
  const input = container.querySelector(`#${label.getAttribute('for')}`)
  return input
}

export function waitForNoElement(queryFn) {
  // use wait instead of waitForElement because waitForElement doesn't seem to
  // trigger the callback when elements disappear
  return wait(() => {
    let elt = null
    try {
      elt = queryFn()
    } catch (e) {
      // if queryFn throws, assume element can't be found and succeed
      return
    }

    // fail if the element was found
    if (elt !== null) throw new Error(`element is still present`)
    // otherwise success
  })
}

export function mockCourse(overrides) {
  return {
    lid: 'course-lid',
    assignmentGroupsConnection: {
      nodes: []
    },
    modulesConnection: {
      nodes: []
    },
    ...overrides
  }
}

export function mockAssignment(overrides) {
  return {
    lid: 'assignment-lid',
    name: 'assignment name',
    pointsPossible: 5,
    dueAt: '2018-11-28T13:00-05:00',
    lockAt: '2018-11-29T13:00-05:00',
    unlockAt: '2018-11-27T13:00-05:00',
    description: 'assignment description',
    state: 'published',
    needsGradingCount: 0,
    course: mockCourse(),
    modules: [{lid: '1', name: 'module 1'}, {lid: '2', name: 'module 2'}],
    assignmentGroup: {lid: '1', name: 'assignment group'},
    lockInfo: {
      isLocked: false
    },
    submissionTypes: ['online_text_entry'],
    allowedExtensions: [],
    allowedAttempts: null,
    assignmentOverrides: {
      nodes: []
    },
    submissions: {
      nodes: []
    },
    ...overrides
  }
}

export function mockOverride(overrides = {}) {
  return {
    gid: '1',
    lid: '1',
    title: 'Section A',
    dueAt: '2018-12-25T23:59:59-05:00',
    allDay: true,
    lockAt: '2018-12-29T23:59:00-05:00',
    unlockAt: '2018-12-23T00:00:00-05:00',
    allowedAttempts: null,
    set: {
      __typename: 'Section',
      lid: '10',
      name: 'Section A'
    },
    ...overrides
  }
}

export function mockSubmission(overrides) {
  return {
    gid: '1',
    lid: '1',
    state: 'submitted',
    submissionStatus: 'submitted',
    gradingStatus: 'needs_grading',
    excused: false,
    latePolicyStatus: null,
    submittedAt: '2019-01-17T12:21:42Z',
    user: mockUser(),
    assetId: '2',
    assetType: 'Submission',
    assessorId: '3',
    assessorAssetId: '33',
    assessorAssetType: 'Submission',
    ...overrides
  }
}

export function mockUser(overrides) {
  return {
    lid: 'user_1',
    gid: 'user_1',
    name: 'User 1',
    ...overrides
  }
}

// values need to match the defaults for TeacherViewContext
export const mockTeacherContext = () => ({...TeacherViewContextDefaults})

// because jsdom doesn't define matchMedia
window.matchMedia =
  window.matchMedia ||
  (() => ({
    matches: false,
    addListener: () => {},
    removeListener: () => {}
  }))
