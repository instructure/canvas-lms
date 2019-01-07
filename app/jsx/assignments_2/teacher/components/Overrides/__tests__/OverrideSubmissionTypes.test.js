/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render} from 'react-testing-library'
import {mockOverride} from '../../../test-utils'
import OverrideSubmissionTypes from '../OverrideSubmissionTypes'

it('renders an override', () => {
  const override = mockOverride({
    submissionTypes: [
      'arc',
      'none',
      'external_tool',
      'o365',
      'online_upload',
      'on_paper',
      'google',
      'online_text_entry',
      'image',
      'online_url',
      'media_recording',
      'any',
      'foo'
    ]
  })
  const {getByText} = render(<OverrideSubmissionTypes variant="simple" override={override} />)

  const submission_types =
    'Arc & No Submission & External Tool & O365 Template & File & On Paper & Google Template & Text Entry & Image & Url & Media & Student Choice & Other'

  const elem = getByText(/^Arc/)
  expect(elem.textContent).toEqual(submission_types)
})
