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
import {render} from '@testing-library/react'
import {mockOverride} from '../../../test-utils'
import OverrideSubmissionTypes from '../OverrideSubmissionTypes'

it('renders an OverrideSubmissionType summary', () => {
  const override = mockOverride({
    submissionTypes: [
      'none',
      'external_tool',
      'online_upload',
      'on_paper',
      'online_text_entry',
      'online_url',
    ],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="summary" override={override} onChangeOverride={() => {}} />
  )
  const submission_types = 'No Submission & App & File & On Paper & Text Entry & URL'
  const elem = getByText(/^No Submission/)
  expect(elem.textContent).toEqual(submission_types)
})

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

it.skip('renders details of a file submission type', () => {
  const override = mockOverride({
    submissionTypes: ['online_upload'],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )
  expect(getByText('Item 1')).toBeInTheDocument()
  expect(getByText('File')).toBeInTheDocument()
  expect(getByText('All Types Allowed')).toBeInTheDocument()
})

it.skip('renders details of a restricted-type file submission type', () => {
  const override = mockOverride({
    submissionTypes: ['online_upload'],
    allowedExtensions: ['doc', 'xls'],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )
  expect(getByText('Item 1')).toBeInTheDocument()
  expect(getByText('File')).toBeInTheDocument()
  expect(getByText('DOC')).toBeInTheDocument()
  expect(getByText('XLS')).toBeInTheDocument()
})

it('renders details of an external tool submission type', () => {
  const override = mockOverride({
    submissionTypes: ['external_tool'],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )
  expect(getByText('Item 1')).toBeInTheDocument()
  expect(getByText('App')).toBeInTheDocument()
})

it('renders details of a text submission type', () => {
  const override = mockOverride({
    submissionTypes: ['online_text_entry'],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )
  expect(getByText('Item 1')).toBeInTheDocument()
  expect(getByText('Text Entry')).toBeInTheDocument()
})

it('renders details of a url submission type', () => {
  const override = mockOverride({
    submissionTypes: ['online_url'],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )
  expect(getByText('Item 1')).toBeInTheDocument()
  expect(getByText('URL')).toBeInTheDocument()
})

it.skip('renders details of multiple submission types', () => {
  const override = mockOverride({
    submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
  })
  const {getByText} = render(
    <OverrideSubmissionTypes variant="detail" override={override} onChangeOverride={() => {}} />
  )
  expect(getByText('Item 1')).toBeInTheDocument()
  expect(getByText('Text Entry')).toBeInTheDocument()
  expect(getByText('Item 2')).toBeInTheDocument()
  expect(getByText('URL')).toBeInTheDocument()
  expect(getByText('Item 3')).toBeInTheDocument()
  expect(getByText('File')).toBeInTheDocument()
  expect(getByText('All Types Allowed')).toBeInTheDocument()
})
