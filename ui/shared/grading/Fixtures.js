/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

let idCounter = 0

function historyEvent() {
  return {
    created_at: '2017-05-30T23:16:59Z',
    event_type: 'grade_change',
    excused_after: false,
    excused_before: false,
    grade_after: 21,
    grade_before: 19,
    graded_anonymously: false,
    id: `fa399876-979e-43c6-93ad-${++idCounter}ef5a41e3ccf`,
    links: {
      assignment: 1,
      course: 1,
      grader: 1,
      page_view: null,
      student: idCounter,
    },
  }
}

function historyEventArray() {
  return [historyEvent(), historyEvent(), historyEvent()]
}

function user() {
  return {
    id: `${++idCounter}`,
    name: `User #${idCounter}`,
  }
}

function userArray() {
  return [user(), user(), user()]
}

function assignment() {
  return {
    id: `${++idCounter}`,
    name: `Assignment #${idCounter}`,
  }
}

function assignmentArray() {
  return [assignment(), assignment(), assignment()]
}

function userMap() {
  const user1 = user()
  const user2 = user()
  const user3 = user()
  const map = {}
  map[`${user1.id}`] = user1.name
  map[`${user2.id}`] = user2.name
  map[`${user3.id}`] = user3.name

  return map
}

function historyResponse() {
  return {
    data: {
      events: historyEventArray(),
      linked: {
        assignments: assignmentArray(),
        courses: [],
        page_views: [],
        users: userArray(),
      },
      links: {},
    },
    headers: {
      'content-type': 'application/json; charset=utf-8',
      date: 'Thu, 01 Jun 2017 00:09:21 GMT',
      link: '<http://example.com/3?&page=first>; rel="current",<http://example.com/3?&page=bookmark:asdf>; rel="next"',
      status: '304 Not Modified',
    },
  }
}

function timeFrame() {
  return {
    from: '2017-05-20T00:00:00-05:00',
    to: '2017-05-25T00:00:00-05:00',
  }
}

export default {
  historyEvent,
  historyEventArray,
  historyResponse,
  timeFrame,
  assignment,
  assignmentArray,
  user,
  userArray,
  userMap,
}
