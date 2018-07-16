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
import React from 'react'
import sinon from 'sinon'
import { shallow } from 'enzyme'
import _ from 'lodash'
import Rubric from '../Rubric'
import { rubric, assessments } from './fixtures'

describe('the Rubric component', () => {
  it('renders as expected', () => {
    const modal = shallow(
      <Rubric
        rubric={rubric}
        rubricAssessment={assessments.points}
        rubricAssociation={assessments.points.rubric_association}
      />
    )
    expect(modal.debug()).toMatchSnapshot()
    expect(modal.find('.react-rubric').prop('style')).toEqual({ minWidth: '52.5rem' })
  })

  it('renders properly with no assessment', () => {
    const modal = shallow(
      <Rubric
        rubric={rubric}
        rubricAssociation={assessments.points.rubric_association}
      />
    )
    expect(modal.debug()).toMatchSnapshot()
  })

  const setCloned = (object, path, value) => _.setWith(_.clone(object), path, value, _.clone)
  it('hides the score total when needed', () => {
    const hidden = setCloned(assessments.points, 'rubric_association.hide_score_total', true)
    const modal = shallow(
      <Rubric
        rubric={rubric}
        rubricAssessment={hidden}
        rubricAssociation={hidden.rubric_association}
      />)
    expect(modal.debug()).toMatchSnapshot()
  })

  it('updates the total score when an individual criterion point assessment changes', () => {
    const onAssessmentChange = sinon.spy()
    const renderAssessing = (assessment) =>
      shallow(
        <Rubric
          onAssessmentChange={onAssessmentChange}
          rubric={rubric}
          rubricAssessment={assessment}
          rubricAssociation={assessment.rubric_association}
        />
      )

    const el = renderAssessing(assessments.points)
    const updated = { ...assessments.points.data[0], points: { valid: true, value: 2 } }
    el.find('Criterion').first().prop('onAssessmentChange')(updated)

    expect(onAssessmentChange.args).toEqual([
      [{
        ...assessments.points,
        data: [updated, assessments.points.data[1]],
        score: 2 + assessments.points.data[1].points.value
      }]
    ])

    expect(renderAssessing(onAssessmentChange.args[0][0]).debug()).toMatchSnapshot()
  })

  describe('points column', () => {
    const hasPointsColumn = (expected, { rubricProps = {}, assessmentProps = {}, associationProps = {}, ...otherProps }) => {
      const el = shallow(
        <Rubric
          rubric={{...rubric, ...rubricProps}}
          rubricAssessment={{...assessments.points, ...assessmentProps}}
          rubricAssociation={{...assessments.points.association, ...associationProps}}
          onAssessmentChange={() => {}}
          {...otherProps}
        />
      )
      expect(el.find('th')).toHaveLength(expected ? 3 : 2)
      expect(el.find('Criterion').at(0).prop('hasPointsColumn')).toBe(expected)
    }

    it('does not have a points column in summary mode', () => {
      hasPointsColumn(false, { isSummary: true })
    })

    it('has a points column if points visible', () => {
      hasPointsColumn(true, {})
    })

    it('does not have a points column if points hidden and freeform', () => {
      hasPointsColumn(false, { rubricProps: { free_form_criterion_comments: true }, associationProps: { hide_points: true }})
    })

    it('does not have a points column if points hidden and not assessing', () => {
      hasPointsColumn(false, { associationProps: { hide_points: true }, onAssessmentChange: null })
    })

    it('does have a points column if points hidden, not freeform, and assessing', () => {
      hasPointsColumn(true, { associationProps: { hide_points: true }})
    })
  })

  it('ignores criteria scores when flagged as such', () => {
    const ignoreOutcomeScore = setCloned(rubric, 'criteria.1.ignore_for_scoring', true)
    const onAssessmentChange = sinon.spy()
    const ignored = {
      ...assessments.points.data[1],
      points: { value: 2, valid: true },
      criterion_id: '_invalid'
    }
    const assessment = setCloned(assessments.points, 'data.2', ignored)
    const el = shallow(
      <Rubric
        onAssessmentChange={onAssessmentChange}
        rubric={ignoreOutcomeScore}
        rubricAssessment={assessment}
        rubricAssociation={assessment.rubric_association}
      />
    )

    const updated = { ...assessment.data[1], points: 2 }
    el.find('Criterion').at(1).prop('onAssessmentChange')(updated)

    expect(onAssessmentChange.args).toEqual([
      [{
        ...assessment,
        data: [assessment.data[0], updated, ignored],
        score: assessment.data[0].points.value
      }]
    ])
  })
})
