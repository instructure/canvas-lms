/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import NameLink from '../NameLink'

const DEFAULT_PROPS = {
  _id: '2',
  children: 'Test User',
  htmlUrl: 'http://test.host/courses/1/users/2'
}

describe('NameLink', () => {
  const setup = props => {
    return render(<NameLink {...props} />)
  }

  beforeEach(() => {
    window.ENV = {
      current_user: {id: '999'}
    }
  })

  it('should render', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container).toBeTruthy()
  })

  it('should render children', () => {
    const container = setup(DEFAULT_PROPS)
    const children = container.getByText(DEFAULT_PROPS.children)
    expect(children).toBeInTheDocument()
  })

  it('should link the current_user to their user detail page when curent_user id matches the argument _id', () => {
    window.ENV = {...window.ENV, current_user: {id: '2'}}
    const container = setup(DEFAULT_PROPS)
    const link = container.getByRole('link', {name: DEFAULT_PROPS.children})
    expect(link).toHaveAttribute('href', DEFAULT_PROPS.htmlUrl)
  })

  it('should not have an href attribute when current_user id does not match argument _id', () => {
    const container = setup(DEFAULT_PROPS)
    const button = container.getByRole('button', {name: DEFAULT_PROPS.children})
    expect(button).not.toHaveAttribute('href')
  })

  it('should trigger its onClick event when its children are clicked', () => {
    const mockCall = jest.fn()
    const container = setup({...DEFAULT_PROPS, onClick: mockCall})
    fireEvent.click(container.getByRole('button', {name: DEFAULT_PROPS.children}))
    expect(mockCall).toHaveBeenCalled()
  })
})
