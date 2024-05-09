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
import {render, screen, waitFor} from '@testing-library/react'
import TutorialTray from '../TutorialTray'
import createTutorialStore from '../../util/createTutorialStore'

const defaultProps = (props = {}, store) => ({
  label: 'TutorialTray Test',
  returnFocusToFunc: () => ({
    focus: () => document.body,
  }),
  store,
  ...props,
})
const renderTutorialTray = (props = {}) => {
  const store = createTutorialStore()
  const ref = React.createRef()
  const wrapper = render(
    <TutorialTray
      {...defaultProps({
        ...props,
        store,
        children: <span>This is the children</span>,
      })}
      ref={ref}
    />
  )

  return {
    ...wrapper,
    store,
    ref,
  }
}

describe('TutorialTray', () => {
  it('renders', () => {
    renderTutorialTray()

    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('handleEntering sets focus on the toggle button', () => {
    const {ref} = renderTutorialTray()

    ref.current.handleToggleClick()
    ref.current.handleEntering()

    expect(ref.current.toggleButton.button.focused).toBe(true)
  })

  it('handleExiting calls focus on the return value of the returnFocusToFunc', () => {
    const focusSpy = jest.fn()
    const fakeReturnFocusToFunc = () => ({focus: focusSpy})
    const {ref} = renderTutorialTray({returnFocusToFunc: fakeReturnFocusToFunc})

    ref.current.handleExiting()

    expect(focusSpy).toHaveBeenCalled()
  })

  it('handleToggleClick toggles the isCollapsed state of the store', () => {
    const {store, ref} = renderTutorialTray()

    ref.current.handleToggleClick()

    expect(store.getState().isCollapsed).toBe(true)
  })

  it('initial state sets endUserTutorialShown to false', () => {
    const {store} = renderTutorialTray()

    waitFor(() => {
      expect(store.getState().endUserTutorialShown).toBe(false)
    })
  })

  it('handleEndTutorialClick sets endUserTutorialShown to true', () => {
    const {ref} = renderTutorialTray()

    ref.current.handleEndTutorialClick()

    expect(ref.current.state.endUserTutorialShown).toBe(true)
  })

  it('closeEndTutorialDialog sets endUserTutorialShown to false', () => {
    const {ref} = renderTutorialTray()

    ref.current.closeEndTutorialDialog()

    expect(ref.current.state.endUserTutorialShown).toBe(false)
  })
})
