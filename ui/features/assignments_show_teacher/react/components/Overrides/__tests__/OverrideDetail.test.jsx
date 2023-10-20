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
import OverrideDetail from '../OverrideDetail'

function renderOD(override, props = {}) {
  return render(
    <OverrideDetail
      override={override}
      onChangeOverride={() => {}}
      onValidate={() => true}
      invalidMessage={() => undefined}
      {...props}
    />
  )
}

describe('OverrideDetail', () => {
  it('renders readonly override details', () => {
    const override = mockOverride({
      submissionTypes: ['online_text_entry', 'online_url', 'media_recording', 'online_upload'],
    })

    const {getByText, getAllByText, getByTestId} = renderOD(override, {readOnly: true})

    // the labels
    expect(getByText('Assign to:')).toBeInTheDocument()
    expect(getByText('Due:')).toBeInTheDocument()
    expect(getByText('Available:')).toBeInTheDocument()
    expect(getByText('Until:')).toBeInTheDocument()
    expect(getAllByText('Submission Items')[0]).toBeInTheDocument()
    expect(getByText('Attempts Allowed')).toBeInTheDocument()
    // the sub-components
    expect(getByTestId('OverrideAssignTo')).toBeInTheDocument()
    expect(getByTestId('OverrideDates')).toBeInTheDocument()
    expect(getByTestId('OverrideSubmissionTypes')).toBeInTheDocument()
    expect(getByTestId('OverrideAttempts-Detail')).toBeInTheDocument()
  })

  it('renders editable override details', () => {
    const override = mockOverride({
      submissionTypes: ['online_text_entry', 'online_url', 'media_recording', 'online_upload'],
    })

    const {getByText, getAllByText, getByTestId} = renderOD(override)

    // the labels
    expect(getByText('Assign to:')).toBeInTheDocument()
    expect(getByText('Due:')).toBeInTheDocument()
    expect(getByText('Available:')).toBeInTheDocument()
    expect(getByText('Until:')).toBeInTheDocument()
    expect(getAllByText('Submission Items')[0]).toBeInTheDocument()
    expect(getByText('Attempts Allowed')).toBeInTheDocument()
    // the sub-components
    expect(getByTestId('OverrideAssignTo')).toBeInTheDocument()
    expect(getByTestId('OverrideDates')).toBeInTheDocument()
    expect(getByTestId('OverrideSubmissionTypes')).toBeInTheDocument()
    expect(getByTestId('OverrideAttempts-Detail')).toBeInTheDocument()
  })
})
