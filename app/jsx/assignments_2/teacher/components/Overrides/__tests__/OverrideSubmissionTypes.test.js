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

it('renders an OverrideSubmissionType summary', () => {
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
  const {getByText} = render(
    <OverrideSubmissionTypes variant="summary" override={override} onChangeOverride={() => {}} />
  )

  const submission_types =
    'Arc & External Tool & File & Google Template & Image & Media & No Submission & O365 Template & On Paper & Student Choice & Text Entry & Url & Other'

  const elem = getByText(/^Arc/)
  expect(elem.textContent).toEqual(submission_types)
})

it('renders an OverrideSubmissionType detail', () => {
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
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )

  expect(getByText('Arc')).toBeInTheDocument()
  expect(getByText('No Submission')).toBeInTheDocument()
  expect(getByText('External Tool')).toBeInTheDocument()
  expect(getByText('O365 Template')).toBeInTheDocument()
  expect(getByText('File')).toBeInTheDocument()
  expect(getByText('On Paper')).toBeInTheDocument()
  expect(getByText('Google Template')).toBeInTheDocument()
  expect(getByText('Text Entry')).toBeInTheDocument()
  expect(getByText('Image')).toBeInTheDocument()
  expect(getByText('Url')).toBeInTheDocument()
  expect(getByText('Media')).toBeInTheDocument()
  expect(getByText('Student Choice')).toBeInTheDocument()
  expect(getByText('Other')).toBeInTheDocument()
})
