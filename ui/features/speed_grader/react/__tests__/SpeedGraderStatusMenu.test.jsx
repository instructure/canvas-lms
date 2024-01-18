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
    window.ENV = {FEATURES: {}}

    props = {
      lateSubmissionInterval: 'day',
      locale: 'en',
      secondsLate: 0,
      selection: 'none',
      updateSubmission: jest.fn(),
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

  it('invokes updateSubmission prop callback with "excuse: true" param when new selection is "excused"', () => {
    selectMenuItem('Excused')
    expect(props.updateSubmission).toHaveBeenLastCalledWith({excuse: true})
  })

  it('invokes updateSubmission prop callback with latePolicyStatus of "late" and a secondsLateOverride param when new selection is "late"', () => {
    selectMenuItem('Late')
    expect(props.updateSubmission).toHaveBeenLastCalledWith({
      latePolicyStatus: 'late',
      secondsLateOverride: props.secondsLate,
    })
  })

  it('invokes updateSubmission prop callback with latePolicyStatus of "missing" when new selection is "missing"', () => {
    selectMenuItem('Missing')
    expect(props.updateSubmission).toHaveBeenLastCalledWith({latePolicyStatus: 'missing'})
  })

  it('invokes updateSubmission prop callback with latePolicyStatus of "none" when new selection is "none"', () => {
    props.selection = 'missing'
    selectMenuItem('None')
    expect(props.updateSubmission).toHaveBeenLastCalledWith({latePolicyStatus: 'none'})
  })

  it('renders custom statuses when they are present', () => {
    props.customStatuses = [
      {id: '1', name: 'Custom Status 1'},
      {id: '2', name: 'Custom Status 2'},
    ]
    const {getByRole, getByText} = renderComponent()
    const trigger = getByRole('button', {name: /Edit status/i})
    fireEvent.click(trigger)
    expect(getByText('Custom Status 1')).toBeInTheDocument()
    expect(getByText('Custom Status 2')).toBeInTheDocument()
  })

  it('invokes updateSubmission prop callback with the custom status id when a custom status is selected', () => {
    props.customStatuses = [
      {id: '14', name: 'Custom Status 1'},
      {id: '23', name: 'Custom Status 2'},
    ]
    selectMenuItem('Custom Status 1')
    expect(props.updateSubmission).toHaveBeenLastCalledWith({customGradeStatusId: '14'})
  })
})
