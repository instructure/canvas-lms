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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {IconAnnotateLine} from '@instructure/ui-icons'
import SubmissionTypeButton from '../SubmissionTypeButton'

const icon = IconAnnotateLine

describe('SubmissionTypeButton', () => {
  describe('when selected', () => {
    it('renders a read-only button', () => {
      const {getByRole} = render(
        <SubmissionTypeButton displayName="Carrier Pigeon" icon={icon} selected={true} />
      )
      expect(getByRole('button')).toBeDisabled()
    })

    it('shows screen-reader content indicating the type is selected', () => {
      const {getByRole} = render(
        <SubmissionTypeButton displayName="Carrier Pigeon" icon={icon} selected={true} />
      )
      expect(getByRole('button')).toHaveTextContent(
        'Submission type Carrier Pigeon, currently selected'
      )
    })
  })

  describe('when not selected', () => {
    it('renders an enabled button', () => {
      const {getByRole} = render(
        <SubmissionTypeButton displayName="Carrier Pigeon" icon={icon} selected={false} />
      )
      expect(getByRole('button')).toBeEnabled()
    })

    it('shows screen-reader content indicating the type can be selected', () => {
      const {getByRole} = render(
        <SubmissionTypeButton displayName="Carrier Pigeon" icon={icon} selected={false} />
      )
      expect(getByRole('button')).toHaveTextContent('Select submission type Carrier Pigeon')
    })
  })

  it('calls the onSelected property when clicked', () => {
    const onSelected = jest.fn()
    const {getByRole} = render(
      <SubmissionTypeButton displayName="Carrier Pigeon" icon={icon} onSelected={onSelected} />
    )
    fireEvent.click(getByRole('button'))
    expect(onSelected).toHaveBeenCalled()
  })

  it('renders the passed-in icon when an element is passed in', () => {
    const {container} = render(<SubmissionTypeButton displayName="Carrier Pigeon" icon={icon} />)

    expect(container.querySelector('svg[name="IconAnnotate"]')).toBeInTheDocument()
  })

  it('renders an image with the specified URL when icon is passed in as a string', () => {
    const {getByRole} = render(<SubmissionTypeButton displayName="Carrier Pigeon" icon="/icon" />)

    expect(getByRole('img')).toHaveAttribute('src', '/icon')
  })
})
