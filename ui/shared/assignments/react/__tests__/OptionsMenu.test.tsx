/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import {
  mockAssignment,
  mockDeleteAssignmentSuccess,
  mockDeleteAssignmentFailure,
} from './test-utils'
import OptionsMenu from '../OptionsMenu'
import {MockedProvider} from '@apollo/client/testing'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

const setUp = (
  propOverrides = {},
  assignmentOverrides = {},
  breakpoints = {},
  mockDeleteSuccess = true,
) => {
  const assignment = mockAssignment({...assignmentOverrides})
  const props = {
    type: 'saved',
    assignment,
    breakpoints,
    ...propOverrides,
  }
  const mocks = mockDeleteSuccess ? [mockDeleteAssignmentSuccess] : [mockDeleteAssignmentFailure]
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <MockedProvider mocks={mocks} addTypename={false}>
        <OptionsMenu {...props} />
      </MockedProvider>
    </QueryClientProvider>,
  )
}

describe('Options Menu', () => {
  describe('download submissions option', () => {
    it('does not render when there are no submissions in saved view', () => {
      const {getByTestId, queryByTestId} = setUp()
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('download-submissions-option')).not.toBeInTheDocument()
    })

    it('renders when there are submissions in saved view', () => {
      const {getByTestId} = setUp({}, {hasSubmittedSubmissions: true})
      getByTestId('assignment-options-button').click()
      expect(getByTestId('download-submissions-option')).toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('download-submissions-option')).not.toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('download-submissions-option')).not.toBeInTheDocument()
    })
  })

  describe('reupload submissions option', () => {
    it('does not render when there are no submission downloads in saved view', () => {
      const {getByTestId, queryByTestId} = setUp({})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('reupload-submissions-option')).not.toBeInTheDocument()
    })

    it('renders when there are submission downloads in saved view', () => {
      const {getByTestId} = setUp(
        {},
        {
          hasSubmittedSubmissions: true,
          submissionsDownloads: 1,
        },
      )
      getByTestId('assignment-options-button').click()
      expect(getByTestId('reupload-submissions-option')).toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('reupload-submissions-option')).not.toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('reupload-submissions-option')).not.toBeInTheDocument()
    })
  })

  describe('peer review option', () => {
    it('renders when peer reviews are required and in saved view', () => {
      const {getByTestId} = setUp({})
      getByTestId('assignment-options-button').click()
      expect(getByTestId('peer-review-option')).toBeInTheDocument()
    })

    it('does not render when peer reviews are not required and in saved view', () => {
      const {getByTestId, queryByTestId} = setUp({}, {peerReviews: {enabled: false}})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('peer-review-option')).not.toBeInTheDocument()
    })

    it('does not render when in edit view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('peer-review-option')).not.toBeInTheDocument()
    })

    it('does not render when in create view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('peer-review-option')).not.toBeInTheDocument()
    })
  })

  describe('send to option', () => {
    it('renders in saved view', () => {
      const {getByTestId} = setUp()
      getByTestId('assignment-options-button').click()
      expect(getByTestId('send-to-option')).toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('send-to-option')).not.toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('send-to-option')).not.toBeInTheDocument()
    })
  })

  describe('copy to option', () => {
    it('renders in saved view', () => {
      const {getByTestId} = setUp()
      getByTestId('assignment-options-button').click()
      expect(getByTestId('copy-to-option')).toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('copy-to-option')).not.toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('copy-to-option')).not.toBeInTheDocument()
    })
  })

  describe('share to commons option', () => {
    it('renders in saved view', () => {
      const {getByTestId} = setUp()
      getByTestId('assignment-options-button').click()
      expect(getByTestId('share-to-commons-option')).toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('share-to-commons-option')).not.toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('share-to-commons-option')).not.toBeInTheDocument()
    })
  })

  describe('delete option', () => {
    it('renders in edit view', () => {
      const {getByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(getByTestId('delete-assignment-option')).toBeInTheDocument()
    })

    it('renders in create view', () => {
      const {getByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(getByTestId('delete-assignment-option')).toBeInTheDocument()
    })

    it('does not render in saved view', () => {
      const {getByTestId, queryByTestId} = setUp()
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('delete-assignment-option')).not.toBeInTheDocument()
    })
  })

  describe('speedgrader option', () => {
    it('renders in the edit view if published', () => {
      const {getByTestId} = setUp({type: 'edit'})
      getByTestId('assignment-options-button').click()
      expect(getByTestId('speedgrader-option')).toBeInTheDocument()
    })

    it('does not render in the edit option if unpublished', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'edit'}, {state: 'unpublished'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('speedgrader-option')).not.toBeInTheDocument()
    })

    it('does not render in the create option', () => {
      const {getByTestId, queryByTestId} = setUp({type: 'create'})
      getByTestId('assignment-options-button').click()
      expect(queryByTestId('speedgrader-option')).not.toBeInTheDocument()
    })
  })

  describe('Mobile View', () => {
    it('renders a more button instead of the traditional icon button', () => {
      const {queryByTestId} = setUp({}, {}, {mobileOnly: true})
      expect(queryByTestId('assignment-options-button')).toBeInTheDocument()
      expect(screen.getByText('More')).toBeInTheDocument()
    })

    it('renders the Edit option', () => {
      const {queryByTestId} = setUp({}, {}, {mobileOnly: true})
      queryByTestId('assignment-options-button')?.click()
      expect(queryByTestId('edit-option')).toBeInTheDocument()
    })

    it('renders the Assign To option', () => {
      const {queryByTestId} = setUp({}, {}, {mobileOnly: true})
      queryByTestId('assignment-options-button')?.click()
      expect(queryByTestId('assign-to-option')).toBeInTheDocument()
    })

    it('renders the SpeedGrader option', () => {
      const {queryByTestId} = setUp({}, {}, {mobileOnly: true})
      queryByTestId('assignment-options-button')?.click()
      expect(queryByTestId('speedgrader-option')).toBeInTheDocument()
    })
  })
})
