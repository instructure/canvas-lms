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

import {isNull} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import ApiProgressBar from '../ApiProgressBar'
import ProgressStore from '../../../stores/ProgressStore'
import sinon from 'sinon'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

let progress_id
let progress
let store_state
let storeSpy
let clock

describe('ApiProgressBarSpec', () => {
  beforeEach(() => {
    progress_id = '1'
    progress = {
      id: progress_id,
      context_id: 1,
      context_type: 'EpubExport',
      user_id: 1,
      tag: 'epub_export',
      completion: 0,
      workflow_state: 'queued',
    }
    store_state = {}
    store_state[progress_id] = progress
    storeSpy = sinon.stub(ProgressStore, 'get').callsFake(() => ProgressStore.setState(store_state))
    clock = sinon.useFakeTimers()
  })

  afterEach(() => {
    ProgressStore.get.restore()
    ProgressStore.clearState()
    clock.restore()
  })

  test('shouldComponentUpdate', function () {
    let ApiProgressBarElement = <ApiProgressBar />
    let component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    ok(
      component.shouldComponentUpdate({progress_id: progress_id}, {}),
      'should update when progress_id prop changes'
    )
    ok(
      component.shouldComponentUpdate({}, {workflow_state: 'running'}),
      'should update when workflow_state changes'
    )
    ok(
      component.shouldComponentUpdate({}, {completion: 10}),
      'should update when completion level changes'
    )

    ApiProgressBarElement = <ApiProgressBar progress_id={progress_id} />
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    component.setState({workflow_state: 'running'})
    ok(
      !component.shouldComponentUpdate(
        {progress_id: progress_id},
        {
          completion: component.state.completion,
          workflow_state: component.state.workflow_state,
        }
      ),
      'should not update if state & props are the same'
    )
  })

  test('componentDidUpdate', function () {
    const onCompleteSpy = sinon.spy()
    const ApiProgressBarElement = (
      <ApiProgressBar onComplete={onCompleteSpy} progress_id={progress_id} />
    )
    const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    clock.tick(component.props.delay + 5)
    ok(!isNull(component.intervalID), 'should have interval id')
    progress.workflow_state = 'running'
    clock.tick(component.props.delay + 5)
    ok(!isNull(component.intervalID), 'should have an inverval id after updating to running')
    progress.workflow_state = 'completed'
    clock.tick(component.props.delay + 5)
    ok(isNull(component.intervalID), 'should not have an inverval id after updating to completed')
    ok(onCompleteSpy.called, 'should call callback on update if complete')
  })

  test('handleStoreChange', function () {
    const ApiProgressBarElement = <ApiProgressBar progress_id={progress_id} />
    const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    clock.tick(component.props.delay + 5)
    ;['completion', 'workflow_state'].forEach(stateName =>
      equal(
        component.state[stateName],
        progress[stateName],
        `component ${stateName} should equal progress ${stateName}`
      )
    )
    progress.workflow_state = 'running'
    progress.completion = 50
    ProgressStore.setState(store_state)
    ;['completion', 'workflow_state'].forEach(stateName =>
      equal(
        component.state[stateName],
        progress[stateName],
        `component ${stateName} should equal progress ${stateName}`
      )
    )
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })

  test('isComplete', function () {
    const ApiProgressBarElement = <ApiProgressBar progress_id={progress_id} />
    const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    clock.tick(component.props.delay + 5)
    ok(!component.isComplete(), 'is not complete if state is queued')
    progress.workflow_state = 'running'
    clock.tick(component.props.delay + 5)
    ok(!component.isComplete(), 'is not complete if state is running')
    progress.workflow_state = 'completed'
    clock.tick(component.props.delay + 5)
    ok(component.isComplete(), 'is complete if state is completed')
  })

  test('isInProgress', function () {
    const ApiProgressBarElement = <ApiProgressBar progress_id={progress_id} />
    const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    clock.tick(component.props.delay + 5)
    ok(component.isInProgress(), 'is in progress if state is queued')
    progress.workflow_state = 'running'
    clock.tick(component.props.delay + 5)
    ok(component.isInProgress(), 'is in progress if state is running')
    progress.workflow_state = 'completed'
    clock.tick(component.props.delay + 5)
    ok(!component.isInProgress(), 'is not in progress if state is completed')
  })

  test('poll', function () {
    let ApiProgressBarElement = <ApiProgressBar />
    let component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    component.poll()
    ok(!storeSpy.called, 'should not fetch from progress store without progress id')

    ApiProgressBarElement = <ApiProgressBar progress_id={progress_id} />
    component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    component.poll()
    ok(storeSpy.called, 'should fetch when progress id is present')
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })

  test('render', function () {
    const ApiProgressBarElement = <ApiProgressBar progress_id={progress_id} />
    const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
    ok(isNull(ReactDOM.findDOMNode(component)), 'should not render to DOM if is not in progress')
    clock.tick(component.props.delay + 5)
    ok(!isNull(ReactDOM.findDOMNode(component)), 'should render to DOM if is not in progress')
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })
})
