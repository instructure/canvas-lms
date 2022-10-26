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

import axios from '@canvas/axios'
import AssignmentApi from 'ui/features/gradebook_history/react/api/AssignmentApi'

QUnit.module('AssignmentApi', {
  setup() {
    this.courseId = 23
    this.getStub = sandbox.stub(axios, 'get').returns(
      Promise.resolve({
        response: {},
      })
    )
  },
})

test('getAssignmentsByName makes a request with a search term', function () {
  const courseId = 23
  const url = `/api/v1/courses/${courseId}/assignments`
  const searchTerm = "Gary's late assignment"
  const params = {
    params: {
      search_term: searchTerm,
    },
  }
  const promise = AssignmentApi.getAssignmentsByName(courseId, searchTerm)

  return promise.then(() => {
    strictEqual(this.getStub.callCount, 1)
    strictEqual(this.getStub.firstCall.args[0], url)
    deepEqual(this.getStub.firstCall.args[1], params)
  })
})

test('getAssignmentsNextPage makes a request with given url', function () {
  const url = 'https://example.com/assignments?page=2'
  const promise = AssignmentApi.getAssignmentsNextPage(url)

  return promise.then(() => {
    strictEqual(this.getStub.callCount, 1)
    strictEqual(this.getStub.firstCall.args[0], url)
  })
})
