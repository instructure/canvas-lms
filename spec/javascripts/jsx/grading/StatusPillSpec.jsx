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

import 'react'
import ReactDOM from 'react-dom'
import {Pill} from '@instructure/ui-pill'
import StatusPill from '@canvas/grading-status-pill'

const wrapper = document.getElementById('fixtures')

function addSpan(className) {
  const span = document.createElement('span')
  span.className = className
  return wrapper.appendChild(span)
}

QUnit.module('StatusPill', {
  setup() {
    wrapper.innerHTML = ''
  },
  tearDown() {
    wrapper.innerHTML = ''
  },
})

test('renderPills mounts a <Pill /> with correct text to each .submission-missing-pill', () => {
  const stubbedRender = sandbox.stub(ReactDOM, 'render')
  const spans = [1, 2, 3].map(() => addSpan('submission-missing-pill'))
  StatusPill.renderPills()

  const calls = spans.map((_span, idx) => stubbedRender.getCall(idx))

  calls.forEach((call, idx) => {
    equal(call.args[0].type, Pill)
    equal(call.args[0].props.children, 'missing')
    equal(call.args[1], spans[idx])
  })
})

test('renderPills mounts a <Pill /> with correct text to each .submission-late-pill', () => {
  const stubbedRender = sandbox.stub(ReactDOM, 'render')
  const spans = [1, 2, 3].map(() => addSpan('submission-late-pill'))
  StatusPill.renderPills()

  const calls = spans.map((_span, idx) => stubbedRender.getCall(idx))

  calls.forEach((call, idx) => {
    equal(call.args[0].type, Pill)
    equal(call.args[0].props.children, 'late')
    equal(call.args[1], spans[idx])
  })
})

test('renderPills mounts a <Pill /> with correct text to each .submission-excused-pill', () => {
  const stubbedRender = sandbox.stub(ReactDOM, 'render')
  const spans = [1, 2, 3].map(() => addSpan('submission-excused-pill'))
  StatusPill.renderPills()

  const calls = spans.map((_span, idx) => stubbedRender.getCall(idx))

  calls.forEach((call, idx) => {
    equal(call.args[0].type, Pill)
    equal(call.args[0].props.children, 'excused')
    equal(call.args[1], spans[idx])
  })
})

test('renderPills mounts a <Pill /> with correct text to each .submission-custom-grade-status-pill-id', () => {
  const stubbedRender = sandbox.stub(ReactDOM, 'render')
  const spans = [1, 2, 3].map(elem => addSpan(`submission-custom-grade-status-pill-${elem}`))
  const statuses = {
    1: {
      name: 'status one',
    },
    2: {
      name: 'status two',
    },
    3: {
      name: 'status three',
    },
  }
  StatusPill.renderPills(statuses)

  const calls = spans.map((_span, idx) => stubbedRender.getCall(idx))
  calls.forEach((call, idx) => {
    equal(call.args[0].type, Pill)
    equal(call.args[0].props.children, statuses[idx].name)
    equal(call.args[1], spans[idx])
  })
})
