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
import TestUtils from 'react-addons-test-utils'
import ApiProgressBar from 'jsx/shared/ApiProgressBar'
import ProgressStore from 'jsx/shared/stores/ProgressStore'

QUnit.module('ApiProgressBarSpec', {
  setup() {
    this.progress_id = '1'
    this.progress = {
      id: this.progress_id,
      context_id: 1,
      context_type: 'EpubExport',
      user_id: 1,
      tag: 'epub_export',
      completion: 0,
      workflow_state: 'queued'
    }
    this.store_state = {}
    this.store_state[this.progress_id] = this.progress
    this.storeSpy = sinon
      .stub(ProgressStore, 'get')
      .callsFake(() => ProgressStore.setState(this.store_state))
    this.clock = sinon.useFakeTimers()
  },
  teardown() {
    ProgressStore.get.restore()
    ProgressStore.clearState()
    return this.clock.restore()
  }
})

test('shouldComponentUpdate', function() {
  const ApiProgressBarElement = <ApiProgressBar />
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  ok(
    component.shouldComponentUpdate({progress_id: this.progress_id}, {}),
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
  component.setProps({progress_id: this.progress_id})
  component.setState({workflow_state: 'running'})
  ok(
    !component.shouldComponentUpdate(
      {progress_id: this.progress_id},
      {
        completion: component.state.completion,
        workflow_state: component.state.workflow_state
      }
    ),
    'should not update if state & props are the same'
  )
})

test('componentDidUpdate', function() {
  const onCompleteSpy = sinon.spy()
  const ApiProgressBarElement = (
    <ApiProgressBar onComplete={onCompleteSpy} progress_id={this.progress_id} />
  )
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  this.clock.tick(component.props.delay + 5)
  ok(!isNull(component.intervalID), 'should have interval id')
  this.progress.workflow_state = 'running'
  this.clock.tick(component.props.delay + 5)
  ok(!isNull(component.intervalID), 'should have an inverval id after updating to running')
  this.progress.workflow_state = 'completed'
  this.clock.tick(component.props.delay + 5)
  ok(isNull(component.intervalID), 'should not have an inverval id after updating to completed')
  ok(onCompleteSpy.called, 'should call callback on update if complete')
})

test('handleStoreChange', function() {
  const ApiProgressBarElement = <ApiProgressBar progress_id={this.progress_id} />
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  this.clock.tick(component.props.delay + 5)
  ;['completion', 'workflow_state'].forEach(stateName =>
    equal(
      component.state[stateName],
      this.progress[stateName],
      `component ${stateName} should equal progress ${stateName}`
    )
  )
  this.progress.workflow_state = 'running'
  this.progress.completion = 50
  ProgressStore.setState(this.store_state)
  ;['completion', 'workflow_state'].forEach(stateName =>
    equal(
      component.state[stateName],
      this.progress[stateName],
      `component ${stateName} should equal progress ${stateName}`
    )
  )
  ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
})

test('isComplete', function() {
  const ApiProgressBarElement = <ApiProgressBar progress_id={this.progress_id} />
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  this.clock.tick(component.props.delay + 5)
  ok(!component.isComplete(), 'is not complete if state is queued')
  this.progress.workflow_state = 'running'
  this.clock.tick(component.props.delay + 5)
  ok(!component.isComplete(), 'is not complete if state is running')
  this.progress.workflow_state = 'completed'
  this.clock.tick(component.props.delay + 5)
  ok(component.isComplete(), 'is complete if state is completed')
})

test('isInProgress', function() {
  const ApiProgressBarElement = <ApiProgressBar progress_id={this.progress_id} />
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  this.clock.tick(component.props.delay + 5)
  ok(component.isInProgress(), 'is in progress if state is queued')
  this.progress.workflow_state = 'running'
  this.clock.tick(component.props.delay + 5)
  ok(component.isInProgress(), 'is in progress if state is running')
  this.progress.workflow_state = 'completed'
  this.clock.tick(component.props.delay + 5)
  ok(!component.isInProgress(), 'is not in progress if state is completed')
})

test('poll', function() {
  const ApiProgressBarElement = <ApiProgressBar />
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  component.poll()
  ok(!this.storeSpy.called, 'should not fetch from progress store without progress id')
  component.setProps({progress_id: this.progress_id})
  component.poll()
  ok(this.storeSpy.called, 'should fetch when progress id is present')
  ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
})

test('render', function() {
  const ApiProgressBarElement = <ApiProgressBar progress_id={this.progress_id} />
  const component = TestUtils.renderIntoDocument(ApiProgressBarElement)
  ok(isNull(component.getDOMNode()), 'should not render to DOM if is not in progress')
  this.clock.tick(component.props.delay + 5)
  ok(!isNull(component.getDOMNode()), 'should render to DOM if is not in progress')
  ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
})
