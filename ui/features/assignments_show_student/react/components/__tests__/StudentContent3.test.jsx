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
import {initializeReaderButton} from '@canvas/immersive-reader/ImmersiveReader'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'

injectGlobalAlertContainers()

jest.mock('../AttemptSelect')

jest.mock('../../apis/ContextModuleApi')

jest.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: jest.fn(),
  }
})

describe('Assignment Student Content View', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {...window.ENV}
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  describe('concluded enrollment notice', () => {
    const concludedMatch = /your enrollment in this course has been concluded/

    beforeEach(() => {
      oldEnv = window.ENV
      window.ENV.can_submit_assignment_from_section = true
      window.ENV = {...window.ENV}
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders when the current enrollment is concluded', async () => {
      window.ENV.enrollment_state = 'completed'

      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      expect(getByText(concludedMatch)).toBeInTheDocument()
    })

    it('renders when the enrollment for the section the assignment is assigned to is concluded', async () => {
      window.ENV.can_submit_assignment_from_section = false
      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      expect(getByText(concludedMatch)).toBeInTheDocument()
    })

    it('does not render when the current enrollment is not concluded', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      expect(queryByText(concludedMatch)).not.toBeInTheDocument()
    })
  })

  describe('Unpublished module', () => {
    it('renders UnpublishedModule', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.belongsToUnpublishedModule = true
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(
        getByText('This assignment is part of an unpublished module and is not available yet.'),
      ).toBeInTheDocument()
    })
  })

  describe('Unavailable peer review', () => {
    it('is rendered when peerReviewModeEnabled is true and peerReviewAvailable is false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.assignment.env.peerReviewAvailable = false
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
          },
        ],
      }
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(
        getByText('There are no submissions available to review just yet.'),
      ).toBeInTheDocument()
      expect(getByText('Please check back soon.')).toBeInTheDocument()
    })

    it('is not rendered when peerReviewModeEnabled is true and peerReviewAvailable is true', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = true
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(
        queryByText('There are no submissions available to review just yet.'),
      ).not.toBeInTheDocument()
      expect(queryByText('Please check back soon.')).not.toBeInTheDocument()
    })

    it('is not rendered when peerReviewModeEnabled is false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(
        queryByText('There are no submissions available to review just yet.'),
      ).not.toBeInTheDocument()
      expect(queryByText('Please check back soon.')).not.toBeInTheDocument()
    })
  })

  describe('Immersive Reader', () => {
    let element
    let props

    beforeEach(async () => {
      props = await mockAssignmentAndSubmission({
        Assignment: {
          description: 'description',
          name: 'name',
        },
      })
    })

    afterEach(() => {
      element?.remove()
      initializeReaderButton.mockClear()
    })

    it('sets up Immersive Reader if it finds the mount point', async () => {
      element = document.createElement('div')
      element.id = 'immersive_reader_mount_point'
      document.documentElement.append(element)

      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      await waitFor(() => {
        expect(initializeReaderButton).toHaveBeenCalledWith(element, {
          content: expect.anything(Function),
          title: 'name',
        })

        expect(initializeReaderButton.mock.calls[0][1].content()).toEqual('description')
      })
    })

    it('sets up Immersive Reader if it finds the mobile mount point', async () => {
      element = document.createElement('div')
      element.id = 'immersive_reader_mobile_mount_point'
      document.documentElement.append(element)

      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      await waitFor(() => {
        expect(initializeReaderButton).toHaveBeenCalledWith(element, {
          content: expect.anything(Function),
          title: 'name',
        })

        expect(initializeReaderButton.mock.calls[0][1].content()).toEqual('description')
      })
    })

    it('does not set up Immersive Reader if neither mount point is present', async () => {
      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(initializeReaderButton).not.toHaveBeenCalled()
    })
  })
})
