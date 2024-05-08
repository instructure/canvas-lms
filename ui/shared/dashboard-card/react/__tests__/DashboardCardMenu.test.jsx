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
import {cleanup, render} from '@testing-library/react'
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

describe('DashboardCardMenu - reordering', () => {
  let wrapper
  let ref

  beforeEach(() => {
    ref = React.createRef()
    wrapper = render(
      <DashboardCardMenu {...defaultProps()} {...defaultMovementMenuProps()} ref={ref} />
    )
  })

  // FOO-3822
  it('it should render a tabList with colorpicker and movement menu', async () => {
    const handleShowPromise = new Promise(resolve => {
      const handleShow = () => {
        expect(ref.current._tabList).toBeTruthy()
        expect(ref.current._colorPicker).toBeTruthy()
        wrapper.getByText('Move').click()
        expect(ref.current._movementMenu).toBeTruthy()
        resolve()
      }

      wrapper.rerender(
        <DashboardCardMenu
          {...defaultProps()}
          {...defaultMovementMenuProps()}
          ref={ref}
          handleShow={handleShow}
        />
      )

      wrapper.getByText('menu').click()
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
        ref.current._closeButton.click()
        expect(popoverContent).toBeFalsy()
        resolve()
      }

      wrapper.rerender(
        <DashboardCardMenu
          {...defaultProps()}
          {...defaultMovementMenuProps()}
          ref={ref}
          handleShow={handleShow}
          popoverContentRef={popoverContentRef}
        />
      )
      wrapper.getByText('menu').click()
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
        ref.current._colorPicker.closeModal()
        expect(popoverContent).toBeFalsy()
        resolve()
      }

      wrapper.rerender(
        <DashboardCardMenu
          {...defaultProps()}
          {...defaultMovementMenuProps()}
          ref={ref}
          handleShow={handleShow}
          popoverContentRef={popoverContentRef}
        />
      )
      wrapper.getByText('menu').click()
    })

    await handleShowPromise
  })

  // FOO-3822
  it('it should close the popover on movement menu option select', async () => {
    let popoverContent
    const popoverContentRef = c => {
      popoverContent = c
    }

    const handleShowPromise = new Promise(resolve => {
      const handleShow = () => {
        wrapper.getByText('Move').click()
        document.querySelectorAll('[role="menuitem"]')[0].click()
        expect(popoverContent).toBeFalsy()
        resolve()
      }

      wrapper.rerender(
        <DashboardCardMenu
          {...defaultProps()}
          {...defaultMovementMenuProps()}
          ref={ref}
          handleShow={handleShow}
          popoverContentRef={popoverContentRef}
        />
      )
      wrapper.getByText('menu').click()
    })

    await handleShowPromise
  })
})
