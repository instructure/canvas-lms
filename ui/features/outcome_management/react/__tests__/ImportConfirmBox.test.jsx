/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, screen, act, fireEvent} from '@testing-library/react'
import ImportConfirmBox, {showImportConfirmBox} from '../ImportConfirmBox'

jest.useFakeTimers()

describe('ImportConfirmBox', () => {
  let alertDiv
  const onCloseHandlerMock = jest.fn()
  const onImportHandlerMock = jest.fn()
  const defaultProps = (props = {}) => ({
    count: 100,
    onCloseHandler: onCloseHandlerMock,
    onImportHandler: onImportHandlerMock,
    ...props,
  })

  beforeEach(async () => {
    alertDiv = document.createElement('div')
    alertDiv.id = 'flashalert_message_holder'
    alertDiv.setAttribute('role', 'alert')
    alertDiv.setAttribute('aria-live', 'assertive')
    alertDiv.setAttribute('aria-relevant', 'additions text')
    alertDiv.setAttribute('aria-atomic', 'false')
    document.body.appendChild(alertDiv)
  })

  afterEach(() => {
    jest.clearAllMocks()
    alertDiv?.parentNode?.removeChild(alertDiv)
    alertDiv = null
  })

  describe('ImportConfirmBox', () => {
    it('shows message with number of outcomes to be imported', () => {
      const {getByText} = render(<ImportConfirmBox {...defaultProps()} />)
      expect(getByText(/You are about to add 100 outcomes to this course./)).toBeInTheDocument()
    })

    it('pluralizes message depending on number of outcomes to be imported', () => {
      const {getByText} = render(<ImportConfirmBox {...defaultProps({count: 1})} />)
      expect(getByText(/You are about to add 1 outcome to this course./)).toBeInTheDocument()
    })

    it('calls onCloseHandler when cancel button is clicked', async () => {
      const {getByText} = render(<ImportConfirmBox {...defaultProps()} />)
      fireEvent.click(getByText('Cancel'))
      await act(async () => jest.runAllTimers())
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('calls onImportHandler and onCloseHandler when Import Anyway button is clicked', async () => {
      const {getByText} = render(<ImportConfirmBox {...defaultProps()} />)
      fireEvent.click(getByText('Import Anyway'))
      await act(async () => jest.runAllTimers())
      expect(onImportHandlerMock).toHaveBeenCalled()
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })
  })

  describe('showImportConfirmBox', () => {
    it('renders ImportConfirmBox when showImportConfirmBox is called', async () => {
      showImportConfirmBox({...defaultProps()})
      expect(
        screen.getByText(/You are about to add 100 outcomes to this course./)
      ).toBeInTheDocument()
    })

    it('calls onCloseHandler before ImportConfirmBox is unmounted', async () => {
      showImportConfirmBox({...defaultProps()})
      fireEvent.click(screen.getByText('Cancel'))
      await act(async () => jest.runAllTimers())
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('creates div element for mounting the ImportConfirmBox', async () => {
      alertDiv.remove()
      showImportConfirmBox({...defaultProps()})
      expect(document.getElementById('flashalert_message_holder')).not.toBeNull()
    })
  })
})
