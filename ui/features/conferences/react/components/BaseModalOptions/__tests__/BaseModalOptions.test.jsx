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

import React from 'react'
import {render} from '@testing-library/react'
import BaseModalOptions from '../BaseModalOptions'

describe('BaseModalOptions', () => {
  const setName = jest.fn()
  const setDuration = jest.fn()
  const setOptions = jest.fn()
  const setDescription = jest.fn()
  const setInvitationOptions = jest.fn()
  const setAttendeesOptions = jest.fn()

  const defaultProps = {
    name: 'Conference 1',
    setName,
    duration: 46,
    setDuration,
    options: [''],
    setOptions,
    description: 'First conference of all time',
    setDescription,
    invitationOptions: ['invite_all'],
    setInvitationOptions,
  }

  const setup = (props = {}) => {
    return render(
      <BaseModalOptions
        name={props.name}
        onSetName={props.setName}
        duration={props.duration}
        onSetDuration={props.setDuration}
        options={props.options}
        onSetOptions={props.setOptions}
        description={props.description}
        onSetDescription={props.setDescription}
        invitationOptions={props.invitationOptions}
        onSetInvitationOptions={props.setInvitationOptions}
      />
    )
  }

  beforeEach(() => {
    setName.mockClear()
    setDuration.mockClear()
    setOptions.mockClear()
    setDescription.mockClear()
    setInvitationOptions.mockClear()
    setAttendeesOptions.mockClear()
  })

  it('should render', () => {
    const container = setup(defaultProps)
    expect(container).toBeTruthy()
  })

  it('should render with default props', () => {
    const {getByLabelText, getAllByLabelText} = setup(defaultProps)
    expect(getByLabelText('Name')).toHaveValue(defaultProps.name)
    expect(getAllByLabelText('Duration in Minutes')[0]).toHaveValue(
      defaultProps.duration.toString()
    )
    expect(getByLabelText('No time limit (for long-running conferences)').checked).toBeFalsy()
    expect(getByLabelText('Description')).toHaveValue(defaultProps.description)
  })
})
