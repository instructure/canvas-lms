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
import {fireEvent, render} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import {queryClient} from '@canvas/query'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'
import {RUBRIC, RUBRIC_ASSOCIATION} from '../../RubricAssignment/__tests__/fixtures'

jest.mock('../queries/RubricFormQueries', () => ({
  ...jest.requireActual('../queries/RubricFormQueries'),
  saveRubric: jest.fn(),
  generateCriteria: jest.fn(),
}))

jest.mock('@canvas/progress/ProgressHelpers', () => ({
  monitorProgress: jest.fn(),
}))

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

describe('RubricForm Tests', () => {
  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      context_asset_string: 'user_1',
    }
  })

  afterEach(() => {
    jest.resetAllMocks()
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

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent?.trim()

  describe('save rubric', () => {
    afterEach(() => {
      jest.resetAllMocks()
    })

    it('will navigate back to /rubrics after successfully saving', async () => {
      jest.spyOn(RubricFormQueries, 'saveRubric').mockImplementation(() =>
        Promise.resolve({
          rubric: {
            id: '1',
            criteriaCount: 1,
            pointsPossible: 10,
            title: 'Rubric 1',
            criteria: [
              {
                id: '1',
                description: 'Criterion 1',
                points: 10,
                criterionUseRange: false,
                ratings: [],
              },
            ],
          },
          rubricAssociation: {
            hidePoints: false,
            hideScoreTotal: false,
            hideOutcomeResults: false,
            id: '1',
            useForGrading: true,
          },
        }),
      )
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      fireEvent.click(getByTestId('add-criterion-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))
      fireEvent.click(getByTestId('save-rubric-button'))

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getSRAlert()).toContain('Rubric saved successfully')
    })

    it('save button is disabled when title is empty', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is disabled when title is whitespace', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: ' '}})
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is disabled when title is 255 whitespace even with criteria', async () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {
        target: {
          value:
            '                                                                                                                                                                                                                                                               ',
        },
      })
      fireEvent.click(getByTestId('add-criterion-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()

      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is enabled when title is 254 whitespace and 1 letter', async () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {
        target: {
          value:
            'e                                                                                                                                                                                                                                                              ',
        },
      })
      fireEvent.click(getByTestId('add-criterion-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()

      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(getByTestId('save-rubric-button')).toBeEnabled()
    })

    it('save button is disabled when there are no criteria', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is enabled when title is not empty and there is criteria', async () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})

      fireEvent.click(getByTestId('add-criterion-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      fireEvent.change(getByTestId('rubric-criterion-name-input'), {
        target: {value: 'New Criterion Test'},
      })
      fireEvent.click(getByTestId('rubric-criterion-save'))

      expect(getByTestId('save-rubric-button')).toBeEnabled()
    })

    it('does not display save as draft button if rubric has associations', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], {
        ...RUBRICS_QUERY_RESPONSE,
        hasRubricAssociations: true,
      })

      const {queryByTestId} = renderComponent({rubricId: '1'})
      expect(queryByTestId('save-as-draft-button')).toBeNull()
    })

    describe('Confirmation Modal', () => {
      afterEach(() => {
        jest.clearAllMocks()
      })

      it('does not render when not on assignment level', () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
        })
        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        const typeInput = getByTestId('rubric-rating-type-select')
        fireEvent.click(typeInput)
        fireEvent.click(getByTestId('rating_type_free_form'))

        const scoringTypeInput = getByTestId('rubric-rating-scoring-type-select')
        fireEvent.click(scoringTypeInput)
        fireEvent.click(getByTestId('scoring_type_unscored'))

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeNull()
      })

      it('does not render when the rubric is unchanged', () => {
        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeNull()
      })

      it('does not render when only assignment level settings are changed', () => {
        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        fireEvent.click(getByTestId('hide-outcome-results-checkbox'))
        fireEvent.click(getByTestId('use-for-grading-checkbox'))
        fireEvent.click(getByTestId('hide-score-total-checkbox'))

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeNull()
      })

      it('renders when the rubric base settings are changed on the assignment level', async () => {
        const {getByTestId, queryByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        const typeInput = getByTestId('rubric-rating-type-select')
        fireEvent.click(typeInput)
        fireEvent.click(getByTestId('rating_type_free_form'))

        const scoringTypeInput = getByTestId('rubric-rating-scoring-type-select')
        fireEvent.click(scoringTypeInput)
        fireEvent.click(getByTestId('scoring_type_unscored'))

        fireEvent.click(getByTestId('rubric-criteria-row-edit-button'))
        // await new Promise(resolve => setTimeout(resolve, 0))
        const criterionNameInput = getByTestId('rubric-criterion-name-input')
        fireEvent.change(criterionNameInput, {target: {value: 'Criterion 1 (edited)'}})
        fireEvent.click(getByTestId('rubric-criterion-save'))

        fireEvent.click(getByTestId('save-rubric-button'))
        expect(queryByTestId('edit-confirm-modal')).toBeInTheDocument()
      })

      it('calls save on confirmation', async () => {
        const {getByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        fireEvent.click(getByTestId('save-rubric-button'))

        fireEvent.click(getByTestId('edit-confirm-btn'))
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(RubricFormQueries.saveRubric).toHaveBeenCalled()
      })

      it('does not call save on cancel', async () => {
        const {getByTestId} = renderComponent({
          rubricId: '1',
          assignmentId: '1',
          rubric: RUBRIC,
          rubricAssociation: RUBRIC_ASSOCIATION,
        })

        const titleInput = getByTestId('rubric-form-title')
        fireEvent.change(titleInput, {target: {value: 'Rubric 1 (edited)'}})

        fireEvent.click(getByTestId('save-rubric-button'))

        fireEvent.click(getByTestId('edit-cancel-btn'))
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(RubricFormQueries.saveRubric).not.toHaveBeenCalled()
      })
    })
  })
})
