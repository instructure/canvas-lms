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
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import {RUBRIC_CRITERIA_IGNORED_FOR_SCORING, RUBRICS_QUERY_RESPONSE} from './fixtures'
import FindDialog from '@canvas/outcomes/backbone/views/FindDialog'
import {WarningModal} from '../components/WarningModal'
import {destroyContainer as destroyFlashAlertContainer} from '@canvas/alerts/react/FlashAlert'
import {reorderRatingsAtIndex} from '../../utils'

vi.mock('../queries/RubricFormQueries', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../queries/RubricFormQueries')>()
  return {
    ...actual,
    saveRubric: vi.fn(),
    generateCriteria: vi.fn(),
  }
})

vi.mock('@canvas/progress/ProgressHelpers', () => ({
  monitorProgress: vi.fn(),
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
    vi.resetAllMocks()
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

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent

  describe('without rubricId', () => {
    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId, getByText} = renderComponent()
      expect(getByText('Create New Rubric')).toBeInTheDocument()
      expect(getByTestId('rubric-form-title')).toHaveValue('')
      // expect(getByTestId('rubric-hide-points-select')).toBeInTheDocument()
      expect(getByTestId('rubric-rating-order-select')).toBeInTheDocument()
      expect(getByTestId('save-as-draft-button')).toBeInTheDocument()
    })
  })

  describe('with rubricId', () => {
    afterEach(() => {
      vi.resetAllMocks()
    })

    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId} = renderComponent({rubricId: '1'})
      expect(getByTestId('rubric-form-title')).toHaveValue('Rubric 1')
    })
  })

  describe('rubric criteria', () => {
    it('renders all criteria rows for a rubric', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId} = renderComponent({rubricId: '1'})
      const criteriaRows = queryAllByTestId('rubric-criteria-row')
      const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
      const criteriaRowLongDescriptions = queryAllByTestId('rubric-criteria-row-long-description')
      const criteriaRowThresholds = queryAllByTestId('rubric-criteria-row-threshold')
      const criteriaRowPoints = queryAllByTestId('rubric-criteria-row-points')
      const criteriaRowIndexes = queryAllByTestId('rubric-criteria-row-index')
      expect(criteriaRows).toHaveLength(2)
      expect(criteriaRowDescriptions[0]).toHaveTextContent(criteria[0].description)
      expect(criteriaRowDescriptions[1]).toHaveTextContent(criteria[1].longDescription ?? '')
      expect(criteriaRowLongDescriptions[0]).toHaveTextContent(criteria[0].longDescription ?? '')
      expect(criteriaRowPoints[0]).toHaveTextContent(criteria[0].points.toString())
      expect(criteriaRowPoints[1]).toHaveTextContent(criteria[1].points.toString())
      expect(criteriaRowIndexes[0]).toHaveTextContent('1.')
      expect(criteriaRowIndexes[1]).toHaveTextContent('2')
      expect(criteriaRowThresholds).toHaveLength(1)
      expect(criteriaRowThresholds[0]).toHaveTextContent('Threshold: 3')
    })

    it('renders the criteria rows without pill if is ignore for scoring', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRIC_CRITERIA_IGNORED_FOR_SCORING)

      const {queryAllByTestId} = renderComponent({rubricId: '1'})
      const criteriaRows = queryAllByTestId('rubric-criteria-row')
      const criteriaRowPoints = queryAllByTestId('rubric-criteria-row-points')

      expect(criteriaRows).toHaveLength(1)
      expect(criteriaRowPoints).toHaveLength(0)
    })

    it('renders the criterion ratings accordion button', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId} = renderComponent({rubricId: '1'})
      const ratingScaleAccordion = queryAllByTestId('criterion-row-rating-accordion')
      expect(ratingScaleAccordion).toHaveLength(2)
      expect(ratingScaleAccordion[0]).toHaveTextContent(
        `Rating Scale: ${criteria[0].ratings.length}`,
      )
      expect(ratingScaleAccordion[1]).toHaveTextContent(
        `Rating Scale: ${criteria[0].ratings.length}`,
      )
    })

    it('renders the criterion ratings accordion items when button is clicked', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {criteria = []} = RUBRICS_QUERY_RESPONSE

      const {queryAllByTestId} = renderComponent({rubricId: '1'})
      const ratingScaleAccordion = queryAllByTestId('criterion-row-rating-accordion')
      fireEvent.click(ratingScaleAccordion[0])
      const ratingScaleAccordionItems = queryAllByTestId('rating-scale-accordion-item')
      expect(ratingScaleAccordionItems).toHaveLength(criteria[0].ratings.length)
    })

    it('does not render the criterion ratings accordion items when accordion is closed', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {queryAllByTestId} = renderComponent({rubricId: '1'})
      const ratingScaleAccordion = queryAllByTestId('criterion-row-rating-accordion')
      fireEvent.click(ratingScaleAccordion[0])
      fireEvent.click(ratingScaleAccordion[0])

      const ratingScaleAccordionItems = queryAllByTestId('rating-scale-accordion-item')
      expect(ratingScaleAccordionItems).toHaveLength(0)
    })

    it('should reorder all criteria after drag and drop, but keep original point values of criteria', () => {
      const criteria = [
        {
          id: '1',
          points: 5,
          description: 'Criterion 1',
          longDescription: 'Long description for criterion 1',
          ignoreForScoring: false,
          masteryPoints: 3,
          criterionUseRange: false,
          ratings: [
            {
              id: '1',
              description: 'Rating 1',
              longDescription: 'Long description for rating 1',
              points: 5,
            },
            {
              id: '2',
              description: 'Rating 2',
              longDescription: 'Long description for rating 2',
              points: 0,
            },
          ],
        },
        {
          id: '2',
          points: 15,
          description: 'Criterion 2',
          longDescription: 'Long description for criterion 2',
          ignoreForScoring: false,
          masteryPoints: 3,
          criterionUseRange: false,
          ratings: [
            {
              id: '1',
              description: 'Rating 1',
              longDescription: 'Long description for rating 1',
              points: 15,
            },
            {
              id: '2',
              description: 'Rating 2',
              longDescription: 'Long description for rating 2',
              points: 0,
            },
          ],
        },
        {
          id: '3',
          points: 10,
          description: 'Criterion 3',
          longDescription: 'Long description for criterion 3',
          ignoreForScoring: false,
          masteryPoints: 3,
          criterionUseRange: false,
          ratings: [
            {
              id: '1',
              description: 'Rating 1',
              longDescription: 'Long description for rating 1',
              points: 10,
            },
            {
              id: '2',
              description: 'Rating 2',
              longDescription: 'Long description for rating 2',
              points: 0,
            },
          ],
        },
      ]

      const startIndex = 0
      const endIndex = 2

      const reorderedCriteria = reorderRatingsAtIndex({list: criteria, startIndex, endIndex})

      expect(reorderedCriteria[0]).toEqual(criteria[1])
      expect(reorderedCriteria[1]).toEqual(criteria[2])
      expect(reorderedCriteria[2]).toEqual(criteria[0])
    })

    it('renders a lock icon with a tooltip next to the outcome name', async () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {queryAllByTestId, getByTestId} = renderComponent({rubricId: '1'})

      const outcomeLockIcons = queryAllByTestId(/^outcome-lock-icon/)
      expect(outcomeLockIcons).toHaveLength(1)

      expect(getByTestId('outcome-lock-icon-2')).toBeInTheDocument()
    })

    describe('freeFormCriterionComments', () => {
      it('does not render accordion when rubric is free form comments', () => {
        queryClient.setQueryData(['fetch-rubric', '1'], {
          ...RUBRICS_QUERY_RESPONSE,
          freeFormCriterionComments: true,
        })

        const {queryAllByTestId, queryAllByText} = renderComponent({rubricId: '1'})
        expect(queryAllByTestId('criterion-row-rating-accordion')).toHaveLength(0)
        expect(
          queryAllByText(
            'This area will be used by the assessor to leave comments related to this criterion.',
          ),
        ).toHaveLength(2)
      })
    })

    /**
     * EVAL-4246
     * This test is skipped because it is dependent on a legacy FindDialog backbone component
     * It currently has failures in packages/jquery and is incompatible with the current React test environment
     * These tests should be re-enabled once the Outcomes Tray React component is implemented
     */
    describe.skip('new outcome criterion modal', () => {
      it('imports an outcome linked criteria when the import button is clicked in the find outcome modal', () => {
        const outcomeData = {
          attributes: {
            points_possible: 10,
            description: '<p>Sample description</p>',
            display_name: 'Sample Outcome Display Name',
            mastery_points: 8,
            ratings: ['A', 'B', 'C'],
          },
          outcomeLink: {
            outcome: {
              title: 'Sample Outcome Title',
              id: '123',
            },
          },
        }
        vi.spyOn(FindDialog.prototype, 'import').mockImplementation(function () {
          // @ts-expect-error
          ;(this as FindDialog).trigger('import', {...outcomeData})
        })
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText, queryAllByTestId} = renderComponent()
        fireEvent.click(getByTestId('create-from-outcome-button'))
        fireEvent.click(getByText('Import'))

        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(3)
        expect(queryAllByTestId('rubric-criteria-row-description')[2]).toHaveTextContent(
          'Sample description',
        ) // removes p tags correctly
        expect(queryAllByTestId('rubric-criteria-outcome-subtitle')[1]).toHaveTextContent(
          'Sample Outcome Display Name',
        )
        expect(queryAllByTestId('rubric-criteria-row-outcome-tag')[1]).toHaveTextContent(
          'Sample Outcome Title',
        )
        expect(queryAllByTestId('rubric-points-possible-1')).toHaveTextContent('20 Points Possible')
      })

      it('imports an outcome linked criteria but ignore for scoring', () => {
        const outcomeData = {
          attributes: {
            points_possible: 10,
            description: '<p>Sample description</p>',
            display_name: 'Sample Outcome Display Name',
            ignore_for_scoring: true,
            mastery_points: 8,
            ratings: ['A', 'B', 'C'],
          },
          outcomeLink: {
            outcome: {
              title: 'Sample Outcome Title',
              id: '123',
            },
          },
        }
        vi.spyOn(FindDialog.prototype, 'import').mockImplementation(function () {
          // @ts-expect-error
          ;(this as FindDialog).trigger('import', {...outcomeData})
        })
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText, queryAllByTestId} = renderComponent()
        fireEvent.click(getByTestId('create-from-outcome-button'))
        fireEvent.click(getByText('Import'))

        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(3)
        expect(queryAllByTestId('rubric-points-possible-1')).toHaveTextContent('10 Points Possible')
      })

      it('displays a flash error if the outcome has already been imported into the current rubric', () => {
        const outcomeData = {
          attributes: {
            points_possible: 10,
            description: '<p>Sample description</p>',
            display_name: 'Sample Outcome Display Name',
            mastery_points: 8,
            ratings: ['A', 'B', 'C'],
          },
          outcomeLink: {
            outcome: {
              title: 'Sample Outcome Title',
              id: '12345',
            },
          },
        }
        vi.spyOn(FindDialog.prototype, 'import').mockImplementation(function () {
          // @ts-expect-error
          ;(this as FindDialog).trigger('import', {...outcomeData})
        })
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)
        const {getByTestId, getByText, getAllByText} = renderComponent()
        fireEvent.click(getByTestId('create-from-outcome-button'))
        fireEvent.click(getByText('Import'))

        expect(
          getAllByText('This Outcome has not been added as it already exists in this rubric.')[0],
        ).toBeInTheDocument()
      })
    })

    describe('criterion modal', () => {
      it('opens the criterion modal when the add criterion button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryByTestId} = renderComponent({rubricId: '1'})
        expect(queryByTestId('rubric-criterion-modal')).toBeNull()
        fireEvent.click(getByTestId('add-criterion-button'))

        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
      })

      it('does not save new criterion when the cancel button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent({rubricId: '1'})
        fireEvent.click(getByTestId('add-criterion-button'))
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-cancel'))
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)
      })

      it('saves new criterion when the save button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent({rubricId: '1'})
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)

        fireEvent.click(getByTestId('add-criterion-button'))
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'New Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))

        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(3)
        const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
        expect(criteriaRowDescriptions[2]).toHaveTextContent('New Criterion Test')
      })

      it('updates existing criterion when the save button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent({rubricId: '1'})
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)

        fireEvent.click(queryAllByTestId('rubric-criteria-row-edit-button')[0])
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'Updated Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-save'))

        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)
        const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
        expect(criteriaRowDescriptions[0]).toHaveTextContent('Updated Criterion Test')
      })

      it('does not update existing criterion when the cancel button is clicked', async () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryAllByTestId} = renderComponent({rubricId: '1'})
        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)

        fireEvent.click(queryAllByTestId('rubric-criteria-row-edit-button')[0])
        await new Promise(resolve => setTimeout(resolve, 0))
        expect(getByTestId('rubric-criterion-modal')).toBeInTheDocument()
        fireEvent.change(getByTestId('rubric-criterion-name-input'), {
          target: {value: 'Updated Criterion Test'},
        })
        fireEvent.click(getByTestId('rubric-criterion-cancel'))

        expect(queryAllByTestId('rubric-criteria-row')).toHaveLength(2)
        const criteriaRowDescriptions = queryAllByTestId('rubric-criteria-row-description')
        expect(criteriaRowDescriptions[0]).not.toHaveTextContent('Updated Criterion Test')
      })
    })
  })

  describe('assessed rubrics', () => {
    afterEach(() => {
      vi.resetAllMocks()
    })

    it('renders appropriate info alert when rubric is assessed', () => {
      const rubricQueryResponse = {...RUBRICS_QUERY_RESPONSE, unassessed: false}
      queryClient.setQueryData(['fetch-rubric', '1'], rubricQueryResponse)

      const {queryByTestId} = renderComponent({rubricId: '1'})
      expect(queryByTestId('rubric-limited-edit-mode-alert')).toBeInTheDocument()
    })
  })

  describe('cannot update rubric', () => {
    it('renders appropriate info alert when rubric is assessed', () => {
      const rubricQueryResponse = {...RUBRICS_QUERY_RESPONSE, canUpdateRubric: false}
      queryClient.setQueryData(['fetch-rubric', '1'], rubricQueryResponse)

      const {queryByTestId} = renderComponent({rubricId: '1'})
      expect(queryByTestId('rubric-cannot-update-alert')).toBeInTheDocument()
    })
  })

  describe('rubric assessment options', () => {
    it('renders the rubric assessment options', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId} = renderComponent({rubricId: '1'})
      expect(getByTestId('rubric-rating-scoring-type-select')).toBeInTheDocument()
      expect(getByTestId('rubric-rating-type-select')).toBeInTheDocument()
    })

    it('does not display options when showAdditionalOptions is set to false', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {queryByTestId} = renderComponent({rubricId: '1', showAdditionalOptions: false})

      expect(queryByTestId('rubric-rating-scoring-type-select')).not.toBeInTheDocument()
      expect(queryByTestId('rubric-rating-type-select')).not.toBeInTheDocument()
      expect(queryByTestId('hide-outcome-results-checkbox')).not.toBeInTheDocument()
      expect(queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
      expect(queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
    })

    describe('assignment level options', () => {
      it('should not be rendered when assignmentId is not provided', () => {
        const {queryByTestId} = renderComponent()

        expect(queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
        expect(queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
        expect(queryByTestId('hide-outcome-results-checkbox')).not.toBeInTheDocument()
      })

      it('should be rendered when assignmentId is provided', () => {
        const {getByTestId} = renderComponent({assignmentId: '1'})

        expect(getByTestId('use-for-grading-checkbox')).toBeInTheDocument()
        expect(getByTestId('hide-score-total-checkbox')).toBeInTheDocument()
        expect(getByTestId('hide-outcome-results-checkbox')).toBeInTheDocument()
      })

      it('should not be rendered when showAdditionalOptions is disabled', () => {
        const {queryByTestId} = renderComponent({showAdditionalOptions: false})

        expect(queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
        expect(queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
        expect(queryByTestId('hide-outcome-results-checkbox')).not.toBeInTheDocument()
      })

      it('hides hideScoreTotal checkbox when useForGrading checkbox checked', () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryByTestId} = renderComponent({rubricId: '1', assignmentId: '1'})

        const useForGradingCheckbox = getByTestId('use-for-grading-checkbox')
        fireEvent.click(useForGradingCheckbox)

        expect(queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
      })

      it('hides use useForGrading and hideScoreTotal checkboxes when scoring type is unscored', () => {
        queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

        const {getByTestId, queryByTestId} = renderComponent({rubricId: '1'})

        const scoringTypeSelect = getByTestId('rubric-rating-scoring-type-select')
        fireEvent.click(scoringTypeSelect)
        fireEvent.click(getByTestId('scoring_type_unscored'))

        expect(queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
        expect(queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
      })
    })

    it('hides points when scoring type is set to unscored', () => {
      queryClient.setQueryData(['fetch-rubric', '1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId, queryByTestId, queryAllByTestId} = renderComponent({rubricId: '1'})

      const scoringTypeSelect = getByTestId('rubric-rating-scoring-type-select')
      fireEvent.click(scoringTypeSelect)
      fireEvent.click(getByTestId('scoring_type_unscored'))

      expect(queryByTestId('rubric-points-possible-1')).not.toBeInTheDocument()
      expect(queryAllByTestId('rubric-criteria-row-points')).toHaveLength(0)
    })
  })

  describe('WarningModal', () => {
    const onDismissMock = vi.fn()
    const onCancelMock = vi.fn()

    beforeEach(() => {
      vi.clearAllMocks()
    })

    it('renders correctly when open', () => {
      const {getByTestId, getByText} = render(
        <WarningModal isOpen={true} onDismiss={onDismissMock} onCancel={onCancelMock} />,
      )

      expect(getByTestId('rubric-assignment-exit-warning-modal')).toBeInTheDocument()
      expect(getByText('Warning')).toBeInTheDocument()
      expect(
        getByText('You are about to exit the rubric editor. Any unsaved changes will be lost.'),
      ).toBeInTheDocument()
      expect(getByText('Exit')).toBeInTheDocument()
      expect(getByText('Cancel')).toBeInTheDocument()
    })

    it('does not render when isOpen is false', () => {
      const {queryByTestId} = render(
        <WarningModal isOpen={false} onDismiss={onDismissMock} onCancel={onCancelMock} />,
      )

      expect(queryByTestId('rubric-assignment-exit-warning-modal')).toBeNull()
    })

    it('calls onDismiss when the close button is clicked', () => {
      const {getByText} = render(
        <WarningModal isOpen={true} onDismiss={onDismissMock} onCancel={onCancelMock} />,
      )

      fireEvent.click(getByText('Cancel'))
      expect(onDismissMock).toHaveBeenCalled()
    })

    it('calls onCancel when the Cancel button is clicked', () => {
      const {getByTestId} = render(
        <WarningModal isOpen={true} onDismiss={onDismissMock} onCancel={onCancelMock} />,
      )

      fireEvent.click(getByTestId('exit-rubric-warning-button'))
      expect(onCancelMock).toHaveBeenCalled()
    })

    it('calls onCancel and onDismiss when the Exit button is clicked', () => {
      const {getByText} = render(
        <WarningModal isOpen={true} onDismiss={onDismissMock} onCancel={onCancelMock} />,
      )

      fireEvent.click(getByText('Exit'))
      expect(onDismissMock).toHaveBeenCalled()
      expect(onCancelMock).toHaveBeenCalled()
    })
  })
})
