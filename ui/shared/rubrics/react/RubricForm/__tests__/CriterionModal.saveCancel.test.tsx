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
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {fireEvent, render} from '@testing-library/react'
import {CriterionModal, type CriterionModalProps} from '../components/CriterionModal/CriterionModal'

describe('CriterionModal Save and Cancel Tests', () => {
  const renderComponent = (props?: Partial<CriterionModalProps>) => {
    return render(
      <CriterionModal
        isOpen={true}
        criterionUseRangeEnabled={true}
        onDismiss={() => {}}
        onSave={() => {}}
        hidePoints={false}
        freeFormCriterionComments={false}
        isFullWidth={true}
        {...props}
      />,
    )
  }

  const DEFAULT_CRITERION: RubricCriterion = {
    id: '1',
    description: 'Test Criterion',
    points: 10,
    criterionUseRange: false,
    ignoreForScoring: false,
    longDescription: '',
    masteryPoints: 0,
    learningOutcomeId: '',
    ratings: [{id: '1', description: 'Test Rating', points: 0, longDescription: ''}],
  }

  const getCriterion = (props?: Partial<RubricCriterion>) => {
    return {
      ...DEFAULT_CRITERION,
      ...props,
    }
  }

  it('save button should not be disabled if there is a criterion name and rating name', () => {
    const criterion = getCriterion()
    const {getByTestId} = renderComponent({criterion})

    expect(getByTestId('rubric-criterion-save')).not.toBeDisabled()
  })

  it('save button should display validation error if there is no criterion name', () => {
    const onSave = vi.fn()
    const criterion = getCriterion({description: ''})

    const {getByTestId, queryByText} = renderComponent({onSave, criterion})

    fireEvent.click(getByTestId('rubric-criterion-save'))

    expect(onSave).not.toHaveBeenCalled()
    expect(queryByText('Criteria Name Required')).not.toBeNull()
  })

  it('save button should display validation error if there is no rating name', () => {
    const onSave = vi.fn()
    const criterion = getCriterion({
      ratings: [{id: '1', description: '', points: 0, longDescription: ''}],
    })

    const {getByTestId, queryByText} = renderComponent({onSave, criterion})

    fireEvent.click(getByTestId('rubric-criterion-save'))

    expect(onSave).not.toHaveBeenCalled()
    expect(queryByText('Rating Name Required')).not.toBeNull()
  })

  it('save button should display validation error if there is only a single rating with no name', () => {
    const onSave = vi.fn()
    const ratings = [
      {id: '1', description: 'Valid', points: 0, longDescription: ''},
      {id: '1', description: 'Valid', points: 0, longDescription: ''},
      {id: '1', description: '', points: 0, longDescription: ''},
      {id: '1', description: 'Valid', points: 0, longDescription: ''},
    ]
    const criterion = getCriterion({ratings})

    const {getByTestId, queryByText} = renderComponent({onSave, criterion})

    fireEvent.click(getByTestId('rubric-criterion-save'))

    expect(onSave).not.toHaveBeenCalled()
    expect(queryByText('Rating Name Required')).not.toBeNull()
  })

  it('should call onSave when save button is clicked', () => {
    const onSave = vi.fn()
    const criterion = getCriterion()

    const {getByTestId} = renderComponent({onSave, criterion})

    fireEvent.click(getByTestId('rubric-criterion-save'))

    expect(onSave).toHaveBeenCalled()
  })

  it('should call onDismiss when cancel button is clicked', () => {
    const onDismiss = vi.fn()
    const {getByTestId} = renderComponent({onDismiss})

    fireEvent.click(getByTestId('rubric-criterion-cancel'))

    const warningModal = getByTestId('rubric-assignment-exit-warning-modal')
    expect(warningModal).toBeInTheDocument()

    const exitWarningModalButton = getByTestId('exit-rubric-warning-button')
    expect(exitWarningModalButton).toBeInTheDocument()

    fireEvent.click(exitWarningModalButton)

    expect(onDismiss).toHaveBeenCalled()
  })
})
