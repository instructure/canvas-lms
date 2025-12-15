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
import {defaultGenerateCriteriaForm} from '../components/AIGeneratedCriteria/GeneratedCriteriaForm'
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
describe('RubricForm AI Regenerate Submit Test', () => {
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

  it('calls regenerate with additional prompt', async () => {
    const assignmentId = '1'
    const courseId = '1'
    const {getByTestId, getByText} = renderComponent({
      aiRubricsEnabled: true,
      assignmentId,
      courseId,
    })

    const generateButton = getByTestId('generate-criteria-button')
    fireEvent.click(generateButton)

    // Advance timers to trigger the initial progress callback
    await act(async () => {
      await vi.advanceTimersByTimeAsync(100)
    })

    await waitFor(() => {
      expect(getByTestId('generate-criteria-header')).toBeInTheDocument()
    })

    const generateCriteriaHeader = getByTestId('generate-criteria-header')

    await waitFor(() => {
      expect(
        within(generateCriteriaHeader).getByTestId('regenerate-criteria-button'),
      ).toBeInTheDocument()
    })

    const regenerateButton = within(generateCriteriaHeader).getByTestId(
      'regenerate-criteria-button',
    )

    expect(regenerateButton).toBeInTheDocument()
    fireEvent.click(regenerateButton)

    await waitFor(() => {
      expect(getByText('Regenerate Criteria')).toBeInTheDocument()
    })

    const additionalPromptInput = getByTestId('additional-prompt-textarea')
    const additionalPrompt = 'User regenerate prompt'

    fireEvent.change(additionalPromptInput, {target: {value: additionalPrompt}})
    expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()

    fireEvent.click(getByTestId('regenerate-criteria-submit-button'))

    await waitFor(() => {
      expect(regenerateCriteriaMock).toHaveBeenCalledWith(
        courseId,
        assignmentId,
        expect.any(Array),
        additionalPrompt,
        undefined,
        defaultGenerateCriteriaForm,
      )
    })
  })
})
