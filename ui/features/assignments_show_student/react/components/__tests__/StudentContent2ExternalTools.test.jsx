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
import {MockedProvider} from '@apollo/client/testing'
import {render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import fakeENV from '@canvas/test-utils/fakeENV'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'

injectGlobalAlertContainers()

vi.mock('../AttemptSelect')

vi.mock('../../apis/ContextModuleApi')

vi.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: vi.fn(),
  }
})

vi.mock('@canvas/assignments/react/AssignmentExternalTools', () => ({
  __esModule: true,
  default: {
    attach: vi.fn(),
  },
}))

describe('StudentContent External Tools', () => {
  beforeEach(() => {
    AssignmentExternalTools.attach.mockClear()
    fakeENV.setup({
      current_user: {id: '1'},
      COURSE_ID: '123',
      ASSIGNMENT_ID: '456',
    })
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the assignment_external_tools mount point', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )

    const mountPoint = container.querySelector('#assignment_external_tools')
    expect(mountPoint).toBeInTheDocument()
  })

  it('attaches AssignmentExternalTools with correct parameters', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(AssignmentExternalTools.attach).toHaveBeenCalledWith(
        container.querySelector('#assignment_external_tools'),
        'assignment_view',
        123,
        456,
      )
    })
  })

  it('attaches AssignmentExternalTools only once', async () => {
    const props = await mockAssignmentAndSubmission()
    const {rerender} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(AssignmentExternalTools.attach).toHaveBeenCalledTimes(1)
    })

    rerender(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )

    expect(AssignmentExternalTools.attach).toHaveBeenCalledTimes(1)
  })
})
