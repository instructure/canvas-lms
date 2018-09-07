/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import mockFilesEnv from '../mockFilesENV'
import React from 'react'
import ReactDOM from 'react-dom'
import {Simulate} from 'react-addons-test-utils'
import $ from 'jquery'
import PublishCloud from 'jsx/shared/PublishCloud'
import FilesystemObject from 'compiled/models/FilesystemObject'

QUnit.module('PublishCloud', {
  setup() {
    this.model = new FilesystemObject({
      locked: true,
      hidden: false,
      id: 42
    })
    this.model.url = function() {
      return `/api/v1/folders/${this.id}`
    }
    const props = {
      model: this.model,
      userCanManageFilesForContext: true
    }
    this.publishCloud = ReactDOM.render(<PublishCloud {...props} />, $('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.publishCloud).parentNode)
  }
})

test('model change event updates components state', function() {
  equal(this.publishCloud.state.published, false, 'published starts off as false')
  this.model.set('locked', false)
  equal(this.publishCloud.state.published, true, 'changing models locked changes it to true')
})

test('clicking a published cloud opens restricted dialog', function() {
  sandbox.stub(ReactDOM, 'render')
  Simulate.click(this.publishCloud.refs.publishCloud)
  ok(ReactDOM.render.calledOnce, 'renders a component inside the dialog')
})

QUnit.module('PublishCloud Student View', {
  setup() {
    this.model = new FilesystemObject({
      locked: false,
      hidden: true,
      lock_at: '2014-02-01',
      unlock_at: '2014-01-01',
      id: 42
    })
    this.model.url = function() {
      return `/api/v1/folders/${this.id}`
    }
    const props = {
      model: this.model,
      userCanManageFilesForContext: false
    }
    this.publishCloud = ReactDOM.render(<PublishCloud {...props} />, $('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.publishCloud).parentNode)
  }
})

test('should display a non clickable restricted dates icon', function() {
  equal(
    this.publishCloud.refs.publishCloud.title,
    'Available after Jan 1, 2014 at 12am until Feb 1, 2014 at 12am',
    'has a available from hoverover'
  )
})

QUnit.module('PublishCloud#togglePublishedState', {
  setup() {
    const props = {
      model: new FilesystemObject({
        hidden: false,
        id: 42
      }),
      userCanManageFilesForContext: true
    }
    this.publishCloud = ReactDOM.render(<PublishCloud {...props} />, $('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.publishCloud).parentNode)
  }
})

test('when published is true, toggles it to false', function() {
  this.publishCloud.setState({published: true})
  this.publishCloud.togglePublishedState()
  equal(this.publishCloud.state.published, false, 'published state should be false')
})

test('when published is false, toggles publish to true and clears restricted state', function() {
  this.publishCloud.setState({
    published: false,
    restricted: true
  })
  this.publishCloud.togglePublishedState()
  equal(this.publishCloud.state.published, true, 'published state should be true')
  equal(this.publishCloud.state.restricted, false, 'published state should be true')
})

test('when published is false, toggles publish to true and sets hidden to false', function() {
  this.publishCloud.setState({
    published: false,
    restricted: true
  })
  this.publishCloud.togglePublishedState()
  equal(this.publishCloud.state.published, true, 'published state should be true')
  equal(this.publishCloud.state.hidden, false, 'hidden is false')
})

QUnit.module('PublishCloud#getInitialState')

test('sets published initial state based on params model hidden property', function() {
  const model = new FilesystemObject({
    locked: false,
    id: 42
  })
  const props = {
    model,
    userCanManageFilesForContext: true
  }
  this.publishCloud = ReactDOM.render(<PublishCloud {...props} />, $('#fixtures')[0])
  equal(this.publishCloud.state.published, !model.get('locked'), 'not locked is published')
  equal(this.publishCloud.state.restricted, false, 'restricted should be false')
  equal(this.publishCloud.state.hidden, false, 'hidden should be false')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.publishCloud).parentNode)
})

test('restricted is true when lock_at/unlock_at is set', function() {
  const model = new FilesystemObject({
    hidden: false,
    lock_at: '123',
    unlock_at: '123',
    id: 42
  })
  const props = {model}
  this.publishCloud = ReactDOM.render(<PublishCloud {...props} />, $('#fixtures')[0])
  equal(this.publishCloud.state.restricted, true, 'restricted is true when lock_at/ulock_at is set')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.publishCloud).parentNode)
})

QUnit.module('PublishCloud#extractStateFromModel')

test('returns object that can be used to set state', function() {
  const model = new FilesystemObject({
    locked: true,
    hidden: true,
    lock_at: '123',
    unlock_at: '123',
    id: 42
  })
  const props = {model}
  this.publishCloud = ReactDOM.render(<PublishCloud {...props} />, $('#fixtures')[0])
  const newModel = new FilesystemObject({
    locked: false,
    hidden: true,
    lock_at: null,
    unlock_at: null
  })
  deepEqual(
    this.publishCloud.extractStateFromModel(newModel),
    {
      hidden: true,
      published: true,
      restricted: false
    },
    'returns object to set state with'
  )
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.publishCloud).parentNode)
})
