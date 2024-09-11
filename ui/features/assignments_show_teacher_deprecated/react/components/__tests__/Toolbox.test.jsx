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
import CanvasValidatedMockedProvider from '@canvas/validated-apollo-mocked-provider'
import {mockAssignment, mockSubmission} from '../../test-utils'
import Toolbox from '../Toolbox'

function renderToolbox(assignment) {
  return render(
    <CanvasValidatedMockedProvider>
      <Toolbox
        assignment={assignment}
        onChangeAssignment={() => {}}
        onSetWorkstate={() => {}}
        onValidate={() => true}
        invalidMessage={() => undefined}
      />
    </CanvasValidatedMockedProvider>
  )
}

describe('assignments 2 teacher view toolbox', () => {
  it('renders basic information', () => {
    const assignment = mockAssignment({
      needsGradingCount: 1,
      submissions: {
        nodes: [mockSubmission({submittedAt: null}), mockSubmission()],
      },
    })

    const {getByLabelText, getByTestId} = renderToolbox(assignment)
    expect(getByLabelText('Published').getAttribute('checked')).toBe('')
    expect(getByTestId('AssignmentPoints')).toBeInTheDocument()
  })

  it('renders unpublished value checkbox', () => {
    const {getByLabelText} = renderToolbox(mockAssignment({state: 'unpublished'}))
    expect(getByLabelText('Published').getAttribute('checked')).toBeFalsy()
  })
})
