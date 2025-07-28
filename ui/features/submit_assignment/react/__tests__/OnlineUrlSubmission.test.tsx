/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import OnlineUrlSubmission from '../OnlineUrlSubmission'
import {render, fireEvent} from '@testing-library/react'

describe('OnlineUrlSubmission', () => {
  const getProps = (override = {}) => {
    return {
      setValue: jest.fn(),
      getShouldShowUrlError: jest.fn(),
      setShouldShowUrlError: jest.fn(),
      ...override,
    }
  }

  it('does not display errors in initial state', () => {
    const {queryByText} = render(<OnlineUrlSubmission {...getProps()} />)
    expect(queryByText('A valid URL is required')).not.toBeInTheDocument()
  })

  it('does not display errors if input is still focused', async () => {
    const {findByTestId, queryByText} = render(<OnlineUrlSubmission {...getProps()} />)
    const urlInput = await findByTestId('online-url-input')
    fireEvent.input(urlInput, {target: {value: 'invalid url'}})
    expect(queryByText('A valid URL is required')).not.toBeInTheDocument()
  })

  it('displays errors on focus if getShouldShowUrlError returns true', async () => {
    const {findByTestId, getByText} = render(
      <OnlineUrlSubmission
        {...getProps({getShouldShowUrlError: jest.fn().mockReturnValue(true)})}
      />
    )
    const urlInput = await findByTestId('online-url-input')
    fireEvent.focus(urlInput)
    expect(getByText('A valid URL is required')).toBeInTheDocument()
  })

  it('clears errors when input is being changed', async () => {
    const setShouldShowUrlErrorMock = jest.fn()
    const {findByTestId, getByText, queryByText} = render(
      <OnlineUrlSubmission {...getProps({getShouldShowUrlError: jest.fn().mockReturnValue(true), setShouldShowUrlError: setShouldShowUrlErrorMock})} />
    )
    const urlInput = await findByTestId('online-url-input')
    fireEvent.input(urlInput, {target: {value: 'invalid url'}})
    fireEvent.focus(urlInput)
    expect(getByText('A valid URL is required')).toBeInTheDocument()
    fireEvent.input(urlInput, {target: {value: 'invalid ur'}})
    expect(queryByText('A valid URL is required')).not.toBeInTheDocument()
    expect(setShouldShowUrlErrorMock).toHaveBeenCalledWith(false)
  })

  it('clears errors on blur if the input is empty', async () => {
    const setShouldShowUrlErrorMock = jest.fn()
    const {findByTestId, queryByText} = render(
      <OnlineUrlSubmission {...getProps({setShouldShowUrlError: setShouldShowUrlErrorMock})} />
    )
    const urlInput = await findByTestId('online-url-input')
    fireEvent.focus(urlInput)
    fireEvent.blur(urlInput)
    expect(queryByText('A valid URL is required')).not.toBeInTheDocument()
  })

  it('calls setValue when the input changes', async () => {
    const setValueMock = jest.fn()
    const {findByTestId} = render(<OnlineUrlSubmission {...getProps({setValue: setValueMock})} />)
    const urlInput = await findByTestId('online-url-input')
    fireEvent.input(urlInput, {target: {value: 'www.'}})
    expect(setValueMock).toHaveBeenCalledWith('www.')
  })
})
