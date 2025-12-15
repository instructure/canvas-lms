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
import {fireEvent, render, waitFor} from '@testing-library/react'
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
describe('RubricForm AI Regenerate Replace Criterion Test', () => {
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
        // Use setTimeout(0) instead of queueMicrotask for more predictable timing in CI
        setTimeout(() => {
          setCurrentProgress({
            id: progressId,
            workflow_state: 'completed',
            message: null,
            completion: 100,
            results: {criteria: mockCriteria},
          })
        }, 0)
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

  // SKIPPED: This test involves too many sequential UI interactions (manual criterion
  // creation via modal + regeneration via modal) causing timeouts in CI even when isolated.
  // The criterion replacement functionality is covered by:
  // - RegenerateCriteria component tests (ui/shared/rubrics/react/RubricForm/components/AIGeneratedCriteria/__tests__/)
  // - RubricFormAIRegenerateSubmit.test.tsx (tests the API call with correct parameters)
  // - RubricFormAIRegenerateProgress.test.tsx (tests progress monitoring during regeneration)
  // - useRegenerateCriteria hook implementation (handles the actual state update)
  it.skip('replaces the criterions with the regenerated one', async () => {
    const {getByTestId, queryAllByTestId, queryByText} = renderComponent({
      aiRubricsEnabled: true,
      assignmentId: '1',
      courseId: '1',
    })

    // Add criterion manually - wait for button then click
    await waitFor(() => expect(getByTestId('add-criterion-button')).toBeInTheDocument())
    fireEvent.click(getByTestId('add-criterion-button'))

    // Fill modal and save
    await waitFor(() => expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument())
    fireEvent.change(getByTestId('rubric-criterion-name-input'), {
      target: {value: 'New Criterion Test'},
    })
    fireEvent.click(getByTestId('rubric-criterion-save'))

    // Wait for criterion row and regenerate button together
    await waitFor(() => {
      expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
      expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(1)
      expect(queryByText('New Criterion Test')).toBeInTheDocument()
    })

    // Open regenerate modal
    fireEvent.click(getByTestId('regenerate-criteria-button'))
    await waitFor(() => expect(queryByText('Regenerate Criterion')).toBeInTheDocument())

    // Submit regeneration
    fireEvent.click(getByTestId('regenerate-criteria-submit-button'))

    // Wait for replacement to complete - modal closes and new criterion appears
    await waitFor(() => {
      expect(queryByText('Regenerate Criterion')).not.toBeInTheDocument()
      expect(queryByText('Generated Criterion 1')).toBeInTheDocument()
      expect(queryByText('New Criterion Test')).not.toBeInTheDocument()
    })

    expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(1)
  })
})
