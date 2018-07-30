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
import _ from 'lodash'
import PropTypes from 'prop-types'
import Table from '@instructure/ui-elements/lib/components/Table'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import I18n from 'i18n!edit_rubric'

import Criterion from './Criterion'

import { rubricShape, rubricAssessmentShape, rubricAssociationShape } from './types'
import { roundIfWhole } from './Points'

const totalString = (score) => I18n.t('Total Points: %{total}', {
  total: I18n.toNumber(score, { precision: 2, strip_insignificant_zeros: true })
})

const totalAssessingString = (score, possible) =>
  I18n.t('Total Points: %{total} out of %{possible}', {
    total: roundIfWhole(score),
    possible: I18n.toNumber(possible, { precision: 2, strip_insignificant_zeros: true })
  })

const Rubric = (props) => {
  const {
    allowExtraCredit,
    customRatings,
    onAssessmentChange,
    rubric,
    rubricAssessment,
    rubricAssociation,
    isSummary
  } = props
  const assessing = onAssessmentChange !== null
  const priorData = _.get(rubricAssessment, 'data', [])
  const byCriteria = _.keyBy(priorData, (ra) => ra.criterion_id)
  const criteriaById = _.keyBy(rubric.criteria, (c) => c.id)
  const allComments = _.get(rubricAssociation, 'summary_data.saved_comments', {})
  const hidePoints = _.get(rubricAssociation, 'hide_points', false)
  const freeForm = rubric.free_form_criterion_comments

  const onCriteriaChange = (id) => (update) => {
    const data = priorData.map((prior) => (
      prior.criterion_id === id ? { ...prior, ...update } : prior
    ))

    const ignore = (c) => _.isUndefined(c) ? true : c.ignore_for_scoring
    const points = data
      .filter((result) => !ignore(criteriaById[result.criterion_id]))
      .map((result) => _.get(result, 'points.value', 0))

    onAssessmentChange({
      ...rubricAssessment,
      data,
      score: _.sum(points)
    })
  }

  // we show the last column for points or comments button
  const showPointsColumn = () => {
    if (isSummary) { return false }
    if (!hidePoints) { return true }
    if (assessing && !freeForm) { return true } // comments button
    return false
  }

  const criteria = rubric.criteria.map((criterion) => {
    const assessment = byCriteria[criterion.id]
    return (
      <Criterion
        allowExtraCredit={allowExtraCredit}
        key={criterion.id}
        assessment={assessment}
        criterion={criterion}
        customRatings={customRatings}
        freeForm={freeForm}
        isSummary={isSummary}
        onAssessmentChange={assessing ? onCriteriaChange(criterion.id) : undefined}
        savedComments={allComments[criterion.id]}
        hidePoints={hidePoints}
        hasPointsColumn={showPointsColumn()}
      />
    )
  })

  const possible = rubric.points_possible
  const points = _.get(rubricAssessment, 'score', possible)
  const total = assessing ? totalAssessingString(points, possible) : totalString(points)
  const hideScoreTotal = _.get(rubricAssociation, 'hide_score_total') === true
  const noScore = _.get(rubricAssociation, 'score') === null
  const showTotalPoints = !hidePoints && !hideScoreTotal
  const criteriaClass = (isSummary || !showPointsColumn()) ? 'rubric-larger-criteria' : undefined
  const maxRatings = _.max(rubric.criteria.map((c) => c.ratings.length))
  const minSize = () => {
    if (isSummary) return {}
    else {
      const ratingCorrection = freeForm ? 0 : 7.5 * maxRatings
      return { 'minWidth': `${30 + (ratingCorrection)}rem` }
    }
  }

  return (
    <div className="react-rubric" style={minSize()}>
      <Table caption={rubric.title}>
        <thead>
          <tr>
            <th scope="col" className={criteriaClass}>
              {I18n.t('Criteria')}
            </th>
            <th scope="col" className="ratings">{I18n.t('Ratings')}</th>
            {
              showPointsColumn() && (
                <th scope="col">{I18n.t('Pts')}</th>
              )
            }
          </tr>
        </thead>
        <tbody className="criterions">
          {criteria}
          { showTotalPoints && (
            <tr>
              <td colSpan="3">
                <Flex justifyItems="end">
                  <FlexItem>
                    {hideScoreTotal || noScore ? null : total}
                  </FlexItem>
                </Flex>
              </td>
            </tr>
          )}
        </tbody>
      </Table>
    </div>
  )
}
Rubric.propTypes = {
  allowExtraCredit: PropTypes.bool,
  customRatings: PropTypes.arrayOf(PropTypes.object),
  onAssessmentChange: PropTypes.func,
  rubric: PropTypes.shape(rubricShape).isRequired,
  rubricAssessment: (props) => {
    const shape = PropTypes.shape(rubricAssessmentShape)
    const rubricAssessment = props.onAssessmentChange ? shape.isRequired : shape
    return PropTypes.checkPropTypes({ rubricAssessment }, props, 'prop', 'Rubric')
  },
  rubricAssociation: PropTypes.shape(rubricAssociationShape),
  isSummary: PropTypes.bool
}
Rubric.defaultProps = {
  allowExtraCredit: false,
  customRatings: [],
  onAssessmentChange: null,
  rubricAssessment: null,
  rubricAssociation: {},
  isSummary: false
}

export default Rubric
