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
import VideoConferenceTypeSelect from '../VideoConferenceTypeSelect'

describe('VideoConferenceTypeSelect', () => {
  const setConferenceType = jest.fn()

  const conferenceTypeOptions = [
    {
      name: 'Adobe Connect',
      type: 'AdobeConnect',
      settings: [],
      free_trial: false,
      send_avatar: false,
      lti_settings: null,
      contexts: null,
    },
    {
      name: 'BigBlueButton',
      type: 'BigBlueButton',
      settings: [],
      free_trial: false,
      send_avatar: false,
      lti_settings: null,
      contexts: null,
    },
  ]

  const setup = () => {
    return render(
      <VideoConferenceTypeSelect
        conferenceTypes={conferenceTypeOptions}
        onSetConferenceType={setConferenceType}
        isEditing={false}
      />
    )
  }

  it('renders conference type select', () => {
    const container = setup()
    expect(container.findByTestId('conference-type-select')).toBeTruthy()
  })

  it('keeps type select enabled when isEditing is falsey', () => {
    const {container} = render(
      <VideoConferenceTypeSelect
        conferenceTypes={conferenceTypeOptions}
        onSetConferenceType={setConferenceType}
        isEditing={false}
      />
    )
    expect(container.querySelector('input')).not.toBeDisabled()
  })

  it('disables type select when isEditing is truthy', () => {
    const {container} = render(
      <VideoConferenceTypeSelect
        conferenceTypes={conferenceTypeOptions}
        onSetConferenceType={setConferenceType}
        isEditing={true}
      />
    )

    expect(container.querySelector('input')).toBeDisabled()
  })
})
