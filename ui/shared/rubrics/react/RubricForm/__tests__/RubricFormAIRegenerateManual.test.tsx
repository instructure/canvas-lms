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
import {fireEvent, render, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
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

// Helper function to add a criterion manually via the modal
async function addCriterionManually(
  getByTestId: (testId: string) => HTMLElement,
  queryAllByTestId: (testId: string) => HTMLElement[],
  criterionName = 'New Criterion Test',
) {
  // Wait for add button to be ready
  await waitFor(() => {
    expect(getByTestId('add-criterion-button')).toBeInTheDocument()
  })

  fireEvent.click(getByTestId('add-criterion-button'))

  await waitFor(() => {
    expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
  })

  fireEvent.change(getByTestId('rubric-criterion-name-input'), {
    target: {value: criterionName},
  })
  fireEvent.click(getByTestId('rubric-criterion-save'))

  // Wait for criterion row to appear
  await waitFor(() => {
    expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
  })

  // Wait for regenerate button to appear separately
  await waitFor(() => {
    expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(1)
  })
}

// SKIPPED: Tests in this file involve manual criterion creation via modal which is slow
// and causes timeouts in CI even when isolated. The error handling functionality is covered by:
// - RubricFormAIRegenerate.test.tsx (tests error handling with AI-generated criteria)
// - Flash alert display is tested in @canvas/alerts tests
describe('RubricForm AI Regenerate Manual Criterion Tests', () => {
  let regenerateCriteriaMock: Mock
  let progressUpdateMock: Mock

  beforeEach(() => {
    fakeEnv.setup({
      context_asset_string: 'user_1',
    })

    regenerateCriteriaMock = RubricFormQueries.regenerateCriteria as Mock
    regenerateCriteriaMock.mockResolvedValue({
      id: 1,
      workflow_state: 'running',
      message: null,
      completion: 1,
    })

    progressUpdateMock = ProgressHelpers.monitorProgress as Mock
    progressUpdateMock.mockImplementation(
      (
        progressId: string,
        setCurrentProgress: (progress: ProgressHelpers.CanvasProgress) => void,
        _onFetchError: (error: Error) => void,
      ) => {
        queueMicrotask(() => {
          setCurrentProgress({
            id: progressId,
            workflow_state: 'completed',
            message: null,
            completion: 100,
            results: {criteria: mockCriteria},
          })
        })
      },
    )
  })

  afterEach(() => {
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

  describe('regenerate single criterion', () => {
    // Note: The 'displays the regenerate dialog with proper content' test has been moved to
    // RubricFormAIRegenerateDialog.test.tsx because it involves multiple UI interactions
    // that cause heavy re-renders, making it slow enough to timeout in CI when combined
    // with other tests.

    // Note: The 'closes the regenerate dialog when cancel is clicked' test has been moved to
    // RubricFormAIRegenerateCancelDialog.test.tsx because it involves multiple UI interactions
    // that cause heavy re-renders, making it slow enough to timeout in CI when combined
    // with other tests.

    // Note: The 'disables the regenerate button when progress is running' test has been moved to
    // RubricFormAIRegenerateProgress.test.tsx because it involves multiple UI interactions
    // that cause heavy re-renders, making it slow enough to timeout in CI when combined
    // with other tests.

    it.skip('displays error message if criteria regeneration fails', async () => {
      regenerateCriteriaMock.mockRejectedValueOnce(new Error('Failed to regenerate'))

      const {getByTestId, queryAllByTestId, queryByText} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      await addCriterionManually(getByTestId, queryAllByTestId)

      fireEvent.click(getByTestId('regenerate-criteria-button'))

      await waitFor(() => {
        expect(queryByText('Regenerate Criterion')).toBeInTheDocument()
      })

      const submitCriterionRegenerateButton = getByTestId('regenerate-criteria-submit-button')
      expect(submitCriterionRegenerateButton).toBeEnabled()
      fireEvent.click(submitCriterionRegenerateButton)

      // Wait for the modal to close using the same pattern as other tests
      await waitForElementToBeRemoved(queryByText('Regenerate Criterion'))

      await waitFor(
        () => {
          expect(document.querySelector('#flashalert_message_holder')).toHaveTextContent(
            'Failed to regenerate criteria',
          )
        },
        {timeout: 5000},
      )
    })

    // Note: The 'replaces the criterions with the regenerated one' test has been moved to
    // RubricFormAIRegenerateReplace.test.tsx because it involves multiple UI interactions
    // that cause heavy re-renders, making it slow enough to timeout in CI when combined
    // with other tests.
  })
})
