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

import React from 'react'
import { mount } from 'enzyme'
import DashboardCardMenu from 'jsx/dashboard_card/DashboardCardMenu'

const defaultProps = () => ({
  trigger: <button>menu</button>,
  assetString: 'course_1',
  afterUpdateColor: () => {},
  currentColor: '#8a8a8a',
  nicknameInfo: {
    nickname: 'foos',
    originalName: 'foosball',
    courseId: '1',
    onNicknameChange: () => {}
  },
  applicationElement: () => document.getElementById('fixtures')
})

const defaultMovementMenuProps = () => ({
  reorderingEnabled: true,
  menuOptions: {
    canMoveLeft: false,
    canMoveRight: true,
    canMoveToBeginning: false,
    canMoveToEnd: true
  }
})

const getTabWithText = (text) => {
  const tabs = Array.from(document.querySelectorAll('[role="tab"]'))
  return tabs.filter(tab => tab.textContent.trim() === text)[0]
}

QUnit.module('DashboardCardMenu - reordering disabled', {
  setup () {
    this.wrapper = mount(<DashboardCardMenu {...defaultProps()} />)
  },

  teardown () {
    this.wrapper.unmount()
  }
})

test('it should render with only a color picker if reordering is not enabled', function (assert) {
  const done = assert.async()

  const handleShow = () => {
    ok(this.wrapper.node._colorPicker)
    notOk(this.wrapper.node._tabList)
    done()
  }

  this.wrapper.setProps({ handleShow }, () => {
    this.wrapper.find('button').simulate('click')
  })
})

QUnit.module('DashboardCardMenu - reordering enabled', {
  setup () {
    this.wrapper = mount(<DashboardCardMenu {...defaultProps()} {...defaultMovementMenuProps()} />)
  },

  teardown () {
    this.wrapper.unmount()
  }
})

test('it should render a tabList with colorpicker and movement menu with reordering enabled', function (assert) {
  const done = assert.async()

  const handleShow = () => {
    ok(this.wrapper.node._tabList)
    ok(this.wrapper.node._colorPicker)
    getTabWithText('Move').click()
    ok(this.wrapper.node._movementMenu)
    done()
  }

  this.wrapper.setProps({ handleShow }, () => {
    this.wrapper.find('button').simulate('click')
  })
})

test('it should close the popover on close button click', function (assert) {
  const done = assert.async()

  let popoverContent
  const popoverContentRef = (c) => {
    popoverContent = c
  }

  const handleShow = () => {
    this.wrapper.node._closeButton.click()
    notOk(popoverContent)
    done()
  }

  this.wrapper.setProps({ handleShow, popoverContentRef }, () => {
    this.wrapper.find('button').simulate('click')
  })
})

test('it should close the popover on color picker close', function (assert) {
  const done = assert.async()

  let popoverContent
  const popoverContentRef = (c) => {
    popoverContent = c
  }

  const handleShow = () => {
    this.wrapper.node._colorPicker.closeModal()
    notOk(popoverContent)
    done()
  }

  this.wrapper.setProps({ handleShow, popoverContentRef }, () => {
    this.wrapper.find('button').simulate('click')
  })
})

test('it should close the popover on movement menu option select', function (assert) {
  const done = assert.async()

  let popoverContent
  const popoverContentRef = (c) => {
    popoverContent = c
  }

  const handleShow = () => {
    getTabWithText('Move').click()
    document.querySelectorAll('[role="menuitem"]')[0].click()
    notOk(popoverContent)
    done()
  }

  this.wrapper.setProps({ handleShow, popoverContentRef }, () => {
    this.wrapper.find('button').simulate('click')
  })
})

