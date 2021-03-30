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
import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {DiscussionThread, mockThreads} from '../DiscussionThread'

const setup = props => {
  return render(<DiscussionThread {...mockThreads} {...props} />)
}

describe('DiscussionThread', () => {
  it('should render', () => {
    const {container} = setup()
    expect(container).toBeTruthy()
  })

  it('should render expand when nested replies are present', () => {
    const {getByTestId} = setup()
    expect(getByTestId('expand-button')).toBeTruthy()
  })

  it('should expand replies when expand button is clicked', () => {
    const {getByTestId} = setup()
    fireEvent.click(getByTestId('expand-button'))
    expect(getByTestId('collapse-replies')).toBeTruthy()
  })

  it('should collapse replies when expand button is clicked', async () => {
    const {getByTestId, queryByTestId} = setup()
    fireEvent.click(getByTestId('expand-button'))
    expect(getByTestId('collapse-replies')).toBeTruthy()

    fireEvent.click(getByTestId('expand-button'))

    expect(queryByTestId('collapse-replies')).toBeNull()
  })

  it('should collapse replies when collapse button is clicked', () => {
    const {getByTestId, queryByTestId} = setup()
    fireEvent.click(getByTestId('expand-button'))
    expect(getByTestId('collapse-replies')).toBeTruthy()

    fireEvent.click(getByTestId('collapse-replies'))

    expect(queryByTestId('collapse-replies')).toBeNull()
  })
})
