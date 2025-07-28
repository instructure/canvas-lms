/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import Modal from '@canvas/modal'
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import ModalButtons from '../buttons'
import ModalContent from '../content'

describe('Modal', () => {
  let $application

  beforeEach(() => {
    // Setup application element
    $application = document.createElement('div')
    $application.id = 'application'
    document.body.appendChild($application)

    // Mock jQuery functions
    const $ = require('jquery')
    $.fn.disableWhileLoading = jest.fn()
  })

  afterEach(() => {
    document.body.removeChild($application)
  })

  const renderModal = props => {
    return render(
      <Modal isOpen={true} title="Hello" {...props}>
        <ModalContent>{props.children || 'inner content'}</ModalContent>
      </Modal>,
    )
  }

  it('has a default class of "ReactModal__Content--canvas"', () => {
    renderModal({})
    expect(screen.getByTestId('canvas-modal')).toBeInTheDocument()
    expect(document.querySelector('.ReactModal__Content--canvas')).toBeInTheDocument()
  })

  it('can create a custom content class', () => {
    renderModal({className: 'custom_class_name'})
    expect(document.querySelector('.custom_class_name')).toBeInTheDocument()
  })

  it('can create a custom overlay class name', () => {
    renderModal({overlayClassName: 'custom_overlay_class_name'})
    expect(document.querySelector('.custom_overlay_class_name')).toBeInTheDocument()
  })

  it('renders ModalContent inside of modal', () => {
    renderModal({
      children: <ModalContent className="childContent">word</ModalContent>,
    })
    expect(document.querySelector('.childContent')).toBeInTheDocument()
  })

  it('renders ModalButtons inside of modal', () => {
    renderModal({
      children: <ModalButtons className="buttonContent">buttons here</ModalButtons>,
    })
    expect(document.querySelector('.buttonContent')).toBeInTheDocument()
  })

  it('closes the modal with the X function when the X is pressed', () => {
    const closeWithX = jest.fn()
    renderModal({closeWithX})

    const closeButton = screen.getByRole('button', {name: 'Close'})
    fireEvent.click(closeButton)

    expect(closeWithX).toHaveBeenCalled()
    expect(document.querySelector('.ReactModal__Layout')).not.toBeInTheDocument()
  })

  it('updates modalIsOpen when props change', () => {
    const onRequestClose = jest.fn()
    const {rerender} = renderModal({isOpen: false, onRequestClose})

    expect(document.querySelector('.ReactModal__Layout')).not.toBeInTheDocument()

    rerender(
      <Modal isOpen={true} onRequestClose={onRequestClose} title="Hello">
        <ModalContent>inner content</ModalContent>
      </Modal>,
    )

    expect(document.querySelector('.ReactModal__Layout')).toBeInTheDocument()
  })

  it('Sets the iframe allowances', () => {
    const onAfterOpen = jest.fn()
    renderModal({onAfterOpen})

    // Wait for next animation frame
    return new Promise(resolve => {
      requestAnimationFrame(() => {
        expect(onAfterOpen).toHaveBeenCalled()
        resolve()
      })
    })
  })

  it('closeModal() sets modal open state to false and calls onRequestClose', () => {
    const onRequestClose = jest.fn()
    renderModal({onRequestClose})

    const closeButton = screen.getByRole('button', {name: 'Close'})
    fireEvent.click(closeButton)

    expect(onRequestClose).toHaveBeenCalled()
    expect(document.querySelector('.ReactModal__Layout')).not.toBeInTheDocument()
  })

  it('defaults to attaching to #application', () => {
    renderModal({})
    expect($application.getAttribute('aria-hidden')).toBe('true')
  })

  it('removes aria-hidden from #application when closed', () => {
    const {unmount} = renderModal({})
    expect($application.getAttribute('aria-hidden')).toBe('true')

    // Trigger the cleanup by clicking the close button
    const closeButton = screen.getByRole('button', {name: 'Close'})
    fireEvent.click(closeButton)

    // After clicking close, aria-hidden should be removed
    expect($application.getAttribute('aria-hidden')).toBeFalsy()
  })

  it('appElement sets react modals app element', () => {
    const appElement = document.createElement('div')
    appElement.id = 'fixtures'
    document.body.appendChild(appElement)

    renderModal({appElement})
    expect(appElement.getAttribute('aria-hidden')).toBe('true')

    document.body.removeChild(appElement)
  })

  it('warns when children are not wrapped in ModalContent or ModalButtons', () => {
    const consoleWarn = jest.spyOn(console, 'warn').mockImplementation(() => {})
    render(
      <Modal isOpen={true} title="Hello">
        <div>Invalid child</div>
      </Modal>,
    )
    expect(consoleWarn).toHaveBeenCalledWith(
      'Modal chilren must be wrapped in either a modal-content or modal-buttons component.',
    )
    consoleWarn.mockRestore()
  })
})
