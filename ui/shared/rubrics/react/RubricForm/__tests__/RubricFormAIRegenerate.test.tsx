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
import {fireEvent, render, within, waitFor, act} from '@testing-library/react'
import {type Mock} from 'vitest'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'
import * as ProgressHelpers from '@canvas/progress/ProgressHelpers'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import {queryClient} from '@canvas/query'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'
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

describe('RubricForm AI Regenerate Tests', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    fakeEnv.setup({
      context_asset_string: 'user_1',
    })
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

  describe('regenerate criteria', () => {
    let generateCriteriaMock: Mock
    let regenerateCriteriaMock: Mock
    let progressUpdateMock: Mock

    beforeEach(() => {
      generateCriteriaMock = RubricFormQueries.generateCriteria as Mock
      generateCriteriaMock.mockResolvedValue({
        id: 1,
        workflow_state: 'running',
        message: null,
        completion: 1,
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
          // Use setTimeout to allow React to process the initial render before setting progress
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
      vi.clearAllMocks()
    })

    it('shows regenerate button after criteria has been generated', async () => {
      const {getByTestId, queryAllByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      // Advance timers to trigger the mocked progress callback
      await act(async () => {
        await vi.advanceTimersByTimeAsync(100)
      })

      await waitFor(() => {
        expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(2)
      })
    })

    it('does not show regenerate button if ai rubrics is enabled and an assignment rubric is being edited', async () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {queryAllByTestId} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
        rubricId: '1',
      })

      await waitFor(() => {
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)
        expect(queryAllByTestId('regenerate-criteria-button')).toHaveLength(0)
      })
    })

    it('displays the regenerate dialog with proper content when regenerate all is initiated', async () => {
      const {getByTestId, getByText} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      // Advance timers to trigger the mocked progress callback
      await act(async () => {
        await vi.advanceTimersByTimeAsync(100)
      })

      // Wait for both the header AND the regenerate button to appear (criteria generation must complete)
      await waitFor(() => {
        const header = getByTestId('generate-criteria-header')
        expect(within(header).getByTestId('regenerate-criteria-button')).toBeInTheDocument()
      })

      const generateCriteriaHeader = getByTestId('generate-criteria-header')
      const regenerateButton = within(generateCriteriaHeader).getByTestId(
        'regenerate-criteria-button',
      )

      expect(regenerateButton).toBeInTheDocument()
      fireEvent.click(regenerateButton)

      await waitFor(() => {
        expect(getByText('Regenerate Criteria')).toBeInTheDocument()
      })

      expect(getByTestId('regenerate-criteria-modal-description')).toHaveTextContent(
        'regenerate the criteria',
      )
      expect(getByTestId('additional-prompt-textarea')).toBeInTheDocument()
    })

    // Validation is tested directly in RegenerateCriteria.test.tsx for faster execution
    it.skip('validates the additional prompt input', async () => {
      const {getByTestId, getByText} = renderComponent({
        aiRubricsEnabled: true,
        assignmentId: '1',
        courseId: '1',
      })

      const generateButton = getByTestId('generate-criteria-button')
      fireEvent.click(generateButton)

      await waitFor(() => {
        const header = getByTestId('generate-criteria-header')
        expect(within(header).getByTestId('regenerate-criteria-button')).toBeInTheDocument()
      })

      const generateCriteriaHeader = getByTestId('generate-criteria-header')
      const regenerateButton = within(generateCriteriaHeader).getByTestId(
        'regenerate-criteria-button',
      )

      fireEvent.click(regenerateButton)

      await waitFor(() => {
        expect(getByText('Regenerate Criteria')).toBeInTheDocument()
      })

      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
      expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()

      const additionalPromptInput = getByTestId('additional-prompt-textarea')
      const longText = 'a'.repeat(1001)

      fireEvent.change(additionalPromptInput, {target: {value: longText}})

      expect(
        getByText('Additional prompt information must be less than 1000 characters'),
      ).toBeInTheDocument()
      expect(getByTestId('regenerate-criteria-submit-button')).toBeDisabled()
    })

    // This test has been moved to RubricFormAIRegenerateSubmit.test.tsx
    // for isolation and reliability. The full RubricForm component with multiple
    // async operations causes timeouts in CI when combined with other tests.
  })
})
