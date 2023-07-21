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
import AnonymousSpeedGraderAlert from 'ui/features/gradebook/react/default_gradebook/components/AnonymousSpeedGraderAlert'

QUnit.module('AnonymousSpeedGraderAlert', suiteHooks => {
  let $applicationElement
  let clock
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    $applicationElement = document.createElement('div')
    $applicationElement.id = 'application'
    document.body.appendChild($applicationElement)

    clock = sinon.useFakeTimers()

    props = {
      onClose() {},
      speedGraderUrl: 'http://test.url:3000',
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $applicationElement.remove()
    clock.restore()
  })

  function mountComponent() {
    wrapper = shallow(<AnonymousSpeedGraderAlert {...props} />)
  }

  function getButton(label) {
    return wrapper
      .find('Button')
      .filterWhere(el => el.children().text() === label)
      .first()
  }

  test('alert is closed initially', () => {
    mountComponent()
    strictEqual(wrapper.find('Alert').prop('open'), false)
  })

  QUnit.module('#open()', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
    })

    test('opens the alert', () => {
      wrapper.instance().open()
      strictEqual(wrapper.find('Alert').prop('open'), true)
      wrapper.instance().close()
      clock.tick(50) // wait for Modal to transition closed
    })
  })

  QUnit.module('when the modal is open', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
      wrapper.instance().open()
    })

    hooks.afterEach(() => {
      wrapper.instance().close()
      clock.tick(50) // wait for Modal to transition closed
    })

    test('overlay has a label of "Anonymous Mode On"', () => {
      equal(wrapper.find('Overlay').prop('label'), 'Anonymous Mode On')
    })

    test('includes a "Cancel" button', () => {
      strictEqual(getButton('Cancel').length, 1)
    })

    test('includes an "Open SpeedGrader" button', () => {
      strictEqual(getButton('Open SpeedGrader').length, 1)
    })

    test('"Open SpeedGrader" button links to the supplied SpeedGrader URL', () => {
      const button = getButton('Open SpeedGrader')
      strictEqual(button.prop('href'), 'http://test.url:3000')
    })

    test('"Cancel" button closes the alert when clicked', () => {
      getButton('Cancel').simulate('click')
      strictEqual(wrapper.find('Alert').prop('open'), false)
    })
  })
})
