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
import {render} from '@testing-library/react'
import NewCollaborationsDropDown from '../NewCollaborationsDropDown'

describe('NewCollaborationsDropDown', () => {
  const ltiCollaborators = [
    {
      id: '1',
      collaboration: {
        enabled: true,
        text: "expected title from 'text' field",
        icon_url: 'https://static.thenounproject.com/png/131630-200.png',
        placement: 'collaboration',
        message_type: 'LtiDeepLinkingRequest',
        target_link_uri: 'http://lti13testtool.docker/launch?placement=collaboration',
        canvas_icon_class: 'icon-lti',
        label: "expected title from 'text' field",
      },
    },
    {
      id: '2',
      collaboration: {
        enabled: true,
        text: "expected title from 'text' field 2",
        icon_url: 'https://static.thenounproject.com/png/131630-200.png',
        placement: 'collaboration',
        message_type: 'LtiDeepLinkingRequest',
        target_link_uri: 'http://lti13testtool.docker/launch?placement=collaboration',
        canvas_icon_class: 'icon-lti',
        label: "expected title from 'text' field 2",
      },
    },
  ]

  beforeEach(() => {
    window.ENV = {context_asset_string: 'course_2'}
  })

  it('renders a dropdown button', () => {
    const {getByTestId} = render(<NewCollaborationsDropDown ltiCollaborators={ltiCollaborators} />)
    expect(getByTestId('new-collaborations-dropdown')).toBeInTheDocument()
  })

  it("when clicked the dropdown button renders a list of lti tool 'text' from settings", () => {
    const {getByText} = render(<NewCollaborationsDropDown ltiCollaborators={ltiCollaborators} />)
    expect(getByText("expected title from 'text' field")).toBeInTheDocument()
    expect(getByText("expected title from 'text' field 2")).toBeInTheDocument()
  })
})
