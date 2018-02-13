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

import axios from 'axios'
import fakeENV from 'helpers/fakeENV'
import api from 'compiled/api/gradingPeriodSetsApi'
import $ from 'jquery'
import 'jquery.ajaxJSON'

const deserializedSets = [
  {
    id: '1',
    title: 'Fall 2015',
    weighted: false,
    displayTotalsForAllGradingPeriods: false,
    gradingPeriods: [
      {
        id: '1',
        title: 'Q1',
        startDate: new Date('2015-09-01T12:00:00Z'),
        endDate: new Date('2015-10-31T12:00:00Z'),
        closeDate: new Date('2015-11-07T12:00:00Z'),
        isClosed: true,
        isLast: false,
        weight: 43.5
      },
      {
        id: '2',
        title: 'Q2',
        startDate: new Date('2015-11-01T12:00:00Z'),
        endDate: new Date('2015-12-31T12:00:00Z'),
        closeDate: new Date('2016-01-07T12:00:00Z'),
        isClosed: false,
        isLast: true,
        weight: null
      }
    ],
    permissions: {
      read: true,
      create: true,
      update: true,
      delete: true
    },
    createdAt: new Date('2015-12-29T12:00:00Z')
  },
  {
    id: '2',
    title: 'Spring 2016',
    weighted: true,
    displayTotalsForAllGradingPeriods: false,
    gradingPeriods: [],
    permissions: {
      read: true,
      create: true,
      update: true,
      delete: true
    },
    createdAt: new Date('2015-11-29T12:00:00Z')
  }
]
const serializedSets = {
  grading_period_sets: [
    {
      id: '1',
      title: 'Fall 2015',
      weighted: false,
      display_totals_for_all_grading_periods: false,
      grading_periods: [
        {
          id: '1',
          title: 'Q1',
          start_date: new Date('2015-09-01T12:00:00Z'),
          end_date: new Date('2015-10-31T12:00:00Z'),
          close_date: new Date('2015-11-07T12:00:00Z'),
          is_closed: true,
          is_last: false,
          weight: 43.5
        },
        {
          id: '2',
          title: 'Q2',
          start_date: new Date('2015-11-01T12:00:00Z'),
          end_date: new Date('2015-12-31T12:00:00Z'),
          close_date: new Date('2016-01-07T12:00:00Z'),
          is_closed: false,
          is_last: true,
          weight: null
        }
      ],
      permissions: {
        read: true,
        create: true,
        update: true,
        delete: true
      },
      created_at: '2015-12-29T12:00:00Z'
    },
    {
      id: '2',
      title: 'Spring 2016',
      weighted: true,
      display_totals_for_all_grading_periods: false,
      grading_periods: [],
      permissions: {
        read: true,
        create: true,
        update: true,
        delete: true
      },
      created_at: '2015-11-29T12:00:00Z'
    }
  ]
}

QUnit.module('gradingPeriodSetsApi.list', {
  setup() {
    this.server = sinon.fakeServer.create()
    this.fakeHeaders = {link: '<http://some_url>; rel="last"'}
    fakeENV.setup()
    ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
  },
  teardown() {
    fakeENV.teardown()
    this.server.restore()
  }
})

test('calls the resolved endpoint', function() {
  this.stub($, 'ajaxJSON').returns(new Promise(() => {}))
  api.list()
  ok($.ajaxJSON.calledWith('api/grading_period_sets'))
})

test('deserializes returned grading period sets', function() {
  let promise
  this.server.respondWith('GET', /grading_period_sets/, [
    200,
    {
      'Content-Type': 'application/json',
      Link: this.fakeHeaders
    },
    JSON.stringify(serializedSets)
  ])
  this.server.autoRespond = true
  return (promise = api.list().then(sets => deepEqual(sets, deserializedSets)))
})

test('creates a title from the creation date when the set has no title', function() {
  const untitledSets = {
    grading_period_sets: [
      {
        id: '1',
        title: null,
        grading_periods: [],
        permissions: {
          read: true,
          create: true,
          update: true,
          delete: true
        },
        created_at: '2015-11-29T12:00:00Z'
      }
    ]
  }
  const jsonString = JSON.stringify(untitledSets)
  this.server.respondWith('GET', /grading_period_sets/, [
    200,
    {
      'Content-Type': 'application/json',
      Link: this.fakeHeaders
    },
    jsonString
  ])
  this.server.autoRespond = true
  return api.list().then(sets => equal(sets[0].title, 'Set created Nov 29, 2015'))
})
const deserializedSetCreating = {
  title: 'Fall 2015',
  weighted: null,
  displayTotalsForAllGradingPeriods: false,
  enrollmentTermIDs: ['1', '2']
}
const deserializedSetCreated = {
  id: '1',
  title: 'Fall 2015',
  weighted: false,
  displayTotalsForAllGradingPeriods: false,
  gradingPeriods: [],
  enrollmentTermIDs: ['1', '2'],
  permissions: {
    read: true,
    create: true,
    update: true,
    delete: true
  },
  createdAt: new Date('2015-12-31T12:00:00Z')
}
const serializedSetCreating = {
  grading_period_set: {
    title: 'Fall 2015',
    weighted: null,
    display_totals_for_all_grading_periods: false
  },
  enrollment_term_ids: ['1', '2']
}
const serializedSetCreated = {
  grading_period_set: {
    id: '1',
    title: 'Fall 2015',
    weighted: false,
    display_totals_for_all_grading_periods: false,
    enrollment_term_ids: ['1', '2'],
    grading_periods: [],
    permissions: {
      read: true,
      create: true,
      update: true,
      delete: true
    },
    created_at: '2015-12-31T12:00:00Z'
  }
}

QUnit.module('gradingPeriodSetsApi.create', {
  setup() {
    fakeENV.setup()
    ENV.GRADING_PERIOD_SETS_URL = 'api/grading_period_sets'
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('calls the resolved endpoint with the serialized grading period set', function() {
  const apiSpy = this.stub(axios, 'post').returns(new Promise(() => {}))
  api.create(deserializedSetCreating)
  ok(axios.post.calledWith('api/grading_period_sets', serializedSetCreating))
})

test('deserializes returned grading period sets', function() {
  const successPromise = new Promise(resolve => resolve({data: serializedSetCreated}))
  this.stub(axios, 'post').returns(successPromise)
  return api.create(deserializedSetCreating).then(set => deepEqual(set, deserializedSetCreated))
})

test('rejects the promise upon errors', function() {
  this.stub(axios, 'post').returns(Promise.reject('FAIL'))
  return api.create(deserializedSetCreating).catch(error => equal(error, 'FAIL'))
})
const deserializedSetUpdating = {
  id: '1',
  title: 'Fall 2015',
  weighted: true,
  displayTotalsForAllGradingPeriods: true,
  enrollmentTermIDs: ['1', '2'],
  permissions: {
    read: true,
    create: true,
    update: true,
    delete: true
  }
}
const serializedSetUpdating = {
  grading_period_set: {
    title: 'Fall 2015',
    weighted: true,
    display_totals_for_all_grading_periods: true
  },
  enrollment_term_ids: ['1', '2']
}
const serializedSetUpdated = {
  grading_period_set: {
    id: '1',
    title: 'Fall 2015',
    weighted: true,
    display_totals_for_all_grading_periods: true,
    enrollment_term_ids: ['1', '2'],
    grading_periods: [
      {
        id: '1',
        title: 'Q1',
        start_date: new Date('2015-09-01T12:00:00Z'),
        end_date: new Date('2015-10-31T12:00:00Z'),
        close_date: new Date('2015-11-07T12:00:00Z'),
        weight: 40
      },
      {
        id: '2',
        title: 'Q2',
        start_date: new Date('2015-11-01T12:00:00Z'),
        end_date: new Date('2015-12-31T12:00:00Z'),
        close_date: null,
        weight: 60
      }
    ],
    permissions: {
      read: true,
      create: true,
      update: true,
      delete: true
    }
  }
}

QUnit.module('gradingPeriodSetsApi.update', {
  setup() {
    fakeENV.setup()
    ENV.GRADING_PERIOD_SET_UPDATE_URL = 'api/grading_period_sets/%7B%7B%20id%20%7D%7D'
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('calls the resolved endpoint with the serialized grading period set', function() {
  const apiSpy = this.stub(axios, 'patch').returns(new Promise(() => {}))
  api.update(deserializedSetUpdating)
  ok(axios.patch.calledWith('api/grading_period_sets/1', serializedSetUpdating))
})

test('returns the given grading period set', function() {
  this.stub(axios, 'patch').returns(Promise.resolve({data: serializedSetUpdated}))
  return api.update(deserializedSetUpdating).then(set => deepEqual(set, deserializedSetUpdating))
})

test('rejects the promise upon errors', function() {
  this.stub(axios, 'patch').returns(Promise.reject('FAIL'))
  return api.update(deserializedSetUpdating).catch(error => equal(error, 'FAIL'))
})
