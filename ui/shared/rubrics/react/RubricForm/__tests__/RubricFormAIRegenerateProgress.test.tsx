/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {fireEvent, render, waitFor, within, act} from '@testing-library/react'
import {type Mock} from 'vitest'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'
import * as ProgressHelpers from '@canvas/progress/ProgressHelpers'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('../queries/RubricFormQueries', async () => ({
  ...(await vi.importActual('../queries/RubricFormQueries')),
  saveRubric: vi.fn(),
  generateCriteria: vi.fn(),
  regenerateCriteria: vi.fn(),
}))

vi.mock('@canvas/progress/ProgressHelpers', () => ({
  monitorProgress: vi.fn(),
}))

const mockCriteria = [
  {
    id: '1',
    description: 'Generated Criterion 1',
    points: 20,
    ratings: [],
    longDescription: '',
    outcome: undefined,
    learningOutcomeId: undefined,
    ignoreForScoring: false,
    criterionUseRange: false,
    masteryPoints: 0,
  },
]

const ROOT_OUTCOME_GROUP = {
  id: '1',
  title: 'Root Outcome Group',
  vendor_guid: '12345',
  subgroups_url: 'https://example.com/subgroups',
  outcomes_url: 'https://example.com/outcomes',
  can_edit: true,
  import_url: 'https://example.com/import',
  context_id: '1',
  context_type: 'Account',
  description: 'Root Outcome Group Description',
  url: 'https://example.com/root',
}

// This test is isolated in its own file because it involves multiple UI interactions
// that cause heavy re-renders, making it slow enough to timeout in CI when
// combined with other tests.
describe('RubricForm AI Regenerate Progress Test', () => {
  let generateCriteriaMock: Mock
  let regenerateCriteriaMock: Mock
  let progressUpdateMock: Mock

  beforeEach(() => {
    vi.useFakeTimers()
    fakeEnv.setup({
      context_asset_string: 'user_1',
    })

    generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
    generateCriteriaMock.mockResolvedValue({
      id: 1,
      workflow_state: 'running',
      message: null,
      completion: 1,
    })

    regenerateCriteriaMock = RubricFormQueries.regenerateCriteria as Mock
    regenerateCriteriaMock.mockResolvedValue({
      id: 2,
      workflow_state: 'running',
      message: null,
      completion: 1,
    })

    progressUpdateMock = ProgressHelpers.monitorProgress as Mock
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.resetAllMocks()
    fakeEnv.teardown()
    destroyFlashAlertContainer()
  })

  const renderComponent = (props?: Partial<RubricFormComponentProp>) => {
    return render(
      <MockedQueryProvider>
        <RubricForm
          rootOutcomeGroup={ROOT_OUTCOME_GROUP}
          criterionUseRangeEnabled={false}
          canManageRubrics={true}
          onCancel={() => {}}
          onSaveRubric={() => {}}
          accountId="1"
          showAdditionalOptions={true}
          aiRubricsEnabled={false}
          {...props}
        />
      </MockedQueryProvider>,
    )
  }

  it('disables the regenerate button when progress is running', async () => {
    // First call to monitorProgress (for initial generate) completes immediately
    // Second call (for regenerate) stays in running state to test disabled button
    let callCount = 0
    progressUpdateMock.mockImplementation(
      (
        progressId: string,
        setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
        _onFetchError: (error: Error) => void,
      ) => {
        callCount++
        if (callCount === 1) {
          // First call (initial generate) - complete immediately
          setTimeout(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'completed',
              message: null,
              completion: 100,
              results: {criteria: mockCriteria},
            })
          }, 0)
        } else {
          // Second call (regenerate) - stay in running state
          setTimeout(() => {
            setCurrentProgress({
              id: progressId,
              workflow_state: 'running',
              message: null,
              completion: 50,
              results: undefined,
            })
          }, 0)
        }
      },
    )

    const {getByTestId, queryByText} = renderComponent({
      aiRubricsEnabled: true,
      assignmentId: '1',
      courseId: '1',
    })

    // Generate initial criteria via AI
    const generateButton = getByTestId('generate-criteria-button')
    fireEvent.click(generateButton)

    // Advance timers to trigger the initial progress callback
    await act(async () => {
      await vi.advanceTimersByTimeAsync(100)
    })

    // Wait for criteria to be generated - should show the header with regenerate button
    await waitFor(() => {
      expect(getByTestId('generate-criteria-header')).toBeInTheDocument()
    })

    // Get the regenerate button from the generated criteria header
    const generateCriteriaHeader = getByTestId('generate-criteria-header')
    const regenerateButton = within(generateCriteriaHeader).getByTestId('regenerate-criteria-button')

    // Open regenerate modal (this is for "all criteria", not single criterion)
    fireEvent.click(regenerateButton)

    await waitFor(() => {
      expect(queryByText('Regenerate Criteria')).toBeInTheDocument()
    })

    // Submit the regeneration
    const submitButton = getByTestId('regenerate-criteria-submit-button')
    expect(submitButton).toBeEnabled()
    fireEvent.click(submitButton)

    // Advance timers to trigger the regenerate progress callback
    await act(async () => {
      await vi.advanceTimersByTimeAsync(100)
    })

    // Wait for the dialog to close
    await waitFor(() => {
      expect(queryByText('Regenerate Criteria')).not.toBeInTheDocument()
    })

    // While progress is running, the regenerate button should be disabled
    await waitFor(() => {
      const headerAfterRegenerate = getByTestId('generate-criteria-header')
      const buttonAfterRegenerate = within(headerAfterRegenerate).getByTestId(
        'regenerate-criteria-button',
      )
      expect(buttonAfterRegenerate).toBeDisabled()
    })
  })
})
