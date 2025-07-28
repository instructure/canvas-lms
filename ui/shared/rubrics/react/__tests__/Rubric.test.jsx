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
import {clone, setWith} from 'lodash'
import React from 'react'
import {render} from '@testing-library/react'
import Rubric from '../Rubric'
import {rubric, assessments} from './fixtures'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('the Rubric component', () => {
  it('renders as expected', () => {
    const {container} = render(
      <Rubric
        rubric={rubric}
        rubricAssessment={assessments.points}
        rubricAssociation={assessments.points.rubric_association}
      />,
    )
    expect(container.querySelector('table')).toBeInTheDocument()
    expect(container.querySelectorAll('[data-testid="rubric-criterion"]')).toHaveLength(2)
  })

  it('renders properly with no assessment', () => {
    const {container} = render(
      <Rubric rubric={rubric} rubricAssociation={assessments.points.rubric_association} />,
    )
    expect(container.querySelector('table')).toBeInTheDocument()
    expect(container.querySelectorAll('[data-testid="rubric-criterion"]')).toHaveLength(2)
  })

  const setCloned = (object, path, value) => setWith(clone(object), path, value, clone)
  it('hides the score total when needed', () => {
    const hidden = setCloned(assessments.points, 'rubric_association.hide_score_total', true)
    const {queryByTestId} = render(
      <Rubric
        rubric={rubric}
        rubricAssessment={hidden}
        rubricAssociation={hidden.rubric_association}
      />,
    )
    expect(queryByTestId('rubric-total')).not.toBeInTheDocument()
  })

  it('forbids comment saving on peer assessments', () => {
    const peer = setCloned(assessments.freeForm, 'assessment_type', 'peer_review')
    const {container} = render(
      <Rubric
        rubric={rubric}
        rubricAssessment={peer}
        rubricAssociation={peer.rubric_association}
      />,
    )
    const commentElements = container.querySelectorAll('[data-testid="save-comment-button"]')
    expect(commentElements).toHaveLength(0)
  })

  it('updates the total score when an individual criterion point assessment changes', () => {
    const onAssessmentChange = jest.fn()
    const {container} = render(
      <Rubric
        onAssessmentChange={onAssessmentChange}
        rubric={rubric}
        rubricAssessment={assessments.points}
        rubricAssociation={assessments.points.rubric_association}
      />,
    )

    expect(container.querySelector('table')).toBeInTheDocument()
    expect(container.querySelectorAll('[data-testid="rubric-criterion"]')).toHaveLength(2)
  })

  describe('points column', () => {
    const hasPointsColumn = (
      expected,
      {rubricProps = {}, assessmentProps = {}, associationProps = {}, ...otherProps},
    ) => {
      const {container, queryAllByTestId} = render(
        <Rubric
          rubric={{...rubric, ...rubricProps}}
          rubricAssessment={{...assessments.points, ...assessmentProps}}
          rubricAssociation={{...assessments.points.association, ...associationProps}}
          onAssessmentChange={() => {}}
          {...otherProps}
        />,
      )
      const pointsHeaders = queryAllByTestId('table-heading-points')
      if (expected) {
        expect(pointsHeaders.length).toBeGreaterThan(0)
      } else {
        expect(pointsHeaders).toHaveLength(0)
      }
      expect(container.querySelector('table')).toBeInTheDocument()
    }

    it('does not have a points column in summary mode', () => {
      hasPointsColumn(false, {isSummary: true})
    })

    it('has a points column if points visible', () => {
      hasPointsColumn(true, {})
    })

    it('does not have a points column if points hidden and freeform', () => {
      hasPointsColumn(false, {
        rubricProps: {free_form_criterion_comments: true},
        associationProps: {hide_points: true},
      })
    })

    it('does not have a points column if points hidden and not assessing', () => {
      hasPointsColumn(false, {associationProps: {hide_points: true}, onAssessmentChange: null})
    })

    it('does have a points column if points hidden, not freeform, and assessing', () => {
      hasPointsColumn(true, {associationProps: {hide_points: true}})
    })
  })

  it('ignores criteria scores when flagged as such', () => {
    const ignoreOutcomeScore = setCloned(rubric, 'criteria.1.ignore_for_scoring', true)
    const onAssessmentChange = jest.fn()
    const ignored = {
      ...assessments.points.data[1],
      points: {value: 2, valid: true},
      criterion_id: '_invalid',
    }
    const assessment = setCloned(assessments.points, 'data.2', ignored)
    const {container} = render(
      <Rubric
        onAssessmentChange={onAssessmentChange}
        rubric={ignoreOutcomeScore}
        rubricAssessment={assessment}
        rubricAssociation={assessment.rubric_association}
      />,
    )

    expect(container.querySelector('table')).toBeInTheDocument()
  })

  it('renders rubric-total and table-heading-points when restrictive quantitative data is false', () => {
    const {getByTestId, queryAllByTestId} = render(
      <Rubric
        rubric={rubric}
        rubricAssessment={assessments.points}
        rubricAssociation={assessments.points.rubric_association}
      />,
    )
    expect(getByTestId('rubric-total')).toBeInTheDocument()
    expect(queryAllByTestId('table-heading-points').length).toBeGreaterThan(0)
  })

  describe('with restrict_quantitative_data', () => {
    beforeEach(() => {
      fakeENV.setup({restrict_quantitative_data: true})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('does not renders rubric-total and table-heading-points when restrictive quantitative data is true', () => {
      const {queryByTestId, queryAllByTestId} = render(
        <Rubric
          rubric={rubric}
          rubricAssessment={assessments.points}
          rubricAssociation={assessments.points.rubric_association}
        />,
      )
      expect(queryByTestId('rubric-total')).not.toBeInTheDocument()
      expect(queryAllByTestId('table-heading-points')).toHaveLength(0)
    })
  })
})
