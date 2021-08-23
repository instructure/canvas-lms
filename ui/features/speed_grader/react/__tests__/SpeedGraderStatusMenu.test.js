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

import SpeedGraderStatusMenu from '../SpeedGraderStatusMenu'
import React from 'react'
import {fireEvent, render} from '@testing-library/react'

describe('SpeedGraderStatusMenu', () => {
  let props

  const renderComponent = () => render(<SpeedGraderStatusMenu {...props} />)

  beforeEach(() => {
    props = {
      lateSubmissionInterval: 'day',
      locale: 'en',
      secondsLate: 0,
      selection: 'none',
      updateSubmission: jest.fn()
    }
  })

  function selectMenuItem(selection) {
    const {getByRole} = renderComponent()
    const trigger = getByRole('button', {name: /Edit status/i})
    fireEvent.click(trigger)
    const menuItem = getByRole('menuitemradio', {name: selection})
    fireEvent.click(menuItem)
  }

  function getTimeLateInput() {
    const searchString = props.lateSubmissionInterval === 'day' ? 'Days late' : 'Hours late'
    const {queryByRole} = renderComponent()
    return queryByRole('textbox', {name: searchString})
  }

  it('renders the time late input when the selection is late', () => {
    props.selection = 'late'
    const timeLateInput = getTimeLateInput()
    expect(timeLateInput).toBeInTheDocument()
  })

  it('does not render the time late input when the selection is not late', () => {
    const timeLateInput = getTimeLateInput()
    expect(timeLateInput).not.toBeInTheDocument()
  })

  it('invokes updateSubmission prop callback when new selection does not match the old selection', () => {
    selectMenuItem('Missing')
    expect(props.updateSubmission).toHaveBeenCalledTimes(1)
  })

  it('does not invoke updateSubmission prop callback when new selection matches the old selection', () => {
    selectMenuItem('None')
    expect(props.updateSubmission).toHaveBeenCalledTimes(0)
  })
})
