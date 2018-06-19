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

import React from 'react'
import {shallow} from 'enzyme'
import AnonymousSpeedGraderAlert from 'jsx/gradezilla/default_gradebook/components/AnonymousSpeedGraderAlert'

function defaultProps(props = {}) {
  return {
    speedGraderUrl: 'http://test.url:3000',
    onClose: () => {},
    ...props
  }
}

QUnit.module('AnonymousSpeedGraderAlert', function(suiteHooks) {
  let clock

  suiteHooks.beforeEach(function() {
    const applicationElement = document.createElement('div')
    applicationElement.id = 'application'
    document.getElementById('fixtures').appendChild(applicationElement)
    clock = sinon.useFakeTimers()
  })

  suiteHooks.afterEach(function() {
    document.getElementById('fixtures').innerHTML = ''
    clock.restore()
  })

  QUnit.module('AnonymousSpeedGraderAlert layout', hooks => {
    let wrapper

    hooks.beforeEach(function() {
      wrapper = shallow(<AnonymousSpeedGraderAlert {...defaultProps()} />)
    })

    hooks.afterEach(function() {
      wrapper.unmount()
      document.getElementById('fixtures').innerHTML = ''
    })

    test('alert is closed initially', function() {
      strictEqual(wrapper.find('Alert').prop('open'), false)
    })

    test('overlay has a label of "Anonymous Mode On"', function() {
      equal(wrapper.find('Overlay').prop('label'), 'Anonymous Mode On')
    })

    test('alert has a "Cancel" button', function() {
      strictEqual(wrapper.find('Button').someWhere(el => el.children().text() === 'Cancel'), true)
    })

    test('alert has an "Open SpeedGrader" button', function() {
      strictEqual(wrapper.find('Button').someWhere(el => el.children().text() === 'Open SpeedGrader'), true)
    })

    test('"Open SpeedGrader" button links to the supplied SpeedGrader URL', function() {
      wrapper.instance().open()

      const openButton = wrapper.find('Button').filterWhere(b => b.children().text() === 'Open SpeedGrader').first();
      strictEqual(openButton.prop('href'), 'http://test.url:3000')
    })

    test('alert opens', function() {
      wrapper.instance().open()
      strictEqual(wrapper.find('Alert').prop('open'), true)
    })

    test('alert unmounts when closed', function() {
      const statusModal = wrapper.instance()
      statusModal.open()
      clock.tick(50) // wait for Modal to transition open
      statusModal.close()
      clock.tick(50) // wait for Modal to transition closed
      strictEqual(wrapper.find('Alert').prop('open'), false)
    })
  })

  QUnit.module('AnonymousSpeedGraderAlert Behavior', hooks => {
    let wrapper

    hooks.beforeEach(function() {
      wrapper = shallow(<AnonymousSpeedGraderAlert {...defaultProps()} />)
    })

    hooks.afterEach(function() {
      wrapper.unmount()
    })

    test('clicking Cancel closes the overlay', function() {
      wrapper.instance().open()

      const cancelButton = wrapper.find('Button').filterWhere(el => el.children().text() === 'Cancel').first()
      cancelButton.simulate('click')
      strictEqual(wrapper.find('Alert').prop('open'), false)
    })
  })
})
