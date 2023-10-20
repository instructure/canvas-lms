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
import {mount} from 'enzyme'
import DashboardCardMenu from '../DashboardCardMenu'

const defaultProps = () => ({
  trigger: <button type="button">menu</button>,
  assetString: 'course_1',
  afterUpdateColor: () => {},
  currentColor: '#8a8a8a',
  nicknameInfo: {
    nickname: 'foos',
    originalName: 'foosball',
    courseId: '1',
    onNicknameChange: () => {},
  },
  applicationElement: () => document.getElementById('fixtures'),
})

const defaultMovementMenuProps = () => ({
  menuOptions: {
    canMoveLeft: false,
    canMoveRight: true,
    canMoveToBeginning: false,
    canMoveToEnd: true,
  },
})

const getTabWithText = text => {
  const tabs = Array.from(document.querySelectorAll('[role="tab"]'))
  return tabs.filter(tab => tab.textContent.trim() === text)[0]
}

describe('DashboardCardMenu - reordering', () => {
  let wrapper

  beforeEach(() => {
    wrapper = mount(<DashboardCardMenu {...defaultProps()} {...defaultMovementMenuProps()} />)
  })

  afterEach(() => {
    wrapper.unmount()
  })

  // FOO-3822
  it.skip('it should render a tabList with colorpicker and movement menu', async () => {
    const handleShowPromise = new Promise(resolve => {
      const handleShow = () => {
        expect(wrapper.instance()._tabList).toBeTruthy()
        expect(wrapper.instance()._colorPicker).toBeTruthy()
        getTabWithText('Move').click()
        expect(wrapper.instance()._movementMenu).toBeTruthy()
        resolve()
      }

      wrapper.setProps({handleShow}, () => {
        wrapper.find('button').simulate('click')
      })
    })

    await handleShowPromise
  })

  it('it should close the popover on close button click', async () => {
    let popoverContent

    const popoverContentRef = c => {
      popoverContent = c
    }

    const handleShowPromise = new Promise(resolve => {
      const handleShow = () => {
        wrapper.instance()._closeButton.click()
        expect(popoverContent).toBeFalsy()
        resolve()
      }

      wrapper.setProps({handleShow, popoverContentRef}, () => {
        wrapper.find('button').simulate('click')
      })
    })

    await handleShowPromise
  })

  it('it should close the popover on color picker close', async () => {
    let popoverContent
    const popoverContentRef = c => {
      popoverContent = c
    }

    const handleShowPromise = new Promise(resolve => {
      const handleShow = () => {
        wrapper.instance()._colorPicker.closeModal()
        expect(popoverContent).toBeFalsy()
        resolve()
      }

      wrapper.setProps({handleShow, popoverContentRef}, () => {
        wrapper.find('button').simulate('click')
      })
    })

    await handleShowPromise
  })

  // FOO-3822
  it.skip('it should close the popover on movement menu option select', async () => {
    let popoverContent
    const popoverContentRef = c => {
      popoverContent = c
    }

    const handleShowPromise = new Promise(resolve => {
      const handleShow = () => {
        getTabWithText('Move').click()
        document.querySelectorAll('[role="menuitem"]')[0].click()
        expect(popoverContent).toBeFalsy()
        resolve()
      }

      wrapper.setProps({handleShow, popoverContentRef}, () => {
        wrapper.find('button').simulate('click')
      })
    })

    await handleShowPromise
  })
})
