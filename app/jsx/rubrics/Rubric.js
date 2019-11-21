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
import {Flex} from '@instructure/ui-layout'
import {get, keyBy, isUndefined, max, sum} from 'lodash'
import I18n from 'i18n!edit_rubricRubric'
import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Table} from '@instructure/ui-elements'

import Criterion from './Criterion'

import {getSavedComments} from './helpers'
import {rubricShape, rubricAssessmentShape, rubricAssociationShape} from './types'
import {roundIfWhole} from './Points'

const totalString = score =>
  I18n.t('Total Points: %{total}', {
    total: I18n.toNumber(score, {precision: 2, strip_insignificant_zeros: true})
  })

const totalAssessingString = (score, possible) =>
  I18n.t('Total Points: %{total} out of %{possible}', {
    total: roundIfWhole(score),
    possible: I18n.toNumber(possible, {precision: 2, strip_insignificant_zeros: true})
  })

const Rubric = props => {
  const {
    allowExtraCredit,
    customRatings,
    onAssessmentChange,
    rubric,
    rubricAssessment,
    rubricAssociation,
    isSummary,
    flexWidth
  } = props

  const peerReview = get(rubricAssessment, 'assessment_type') === 'peer_review'
  const assessing = onAssessmentChange !== null
  const priorData = get(rubricAssessment, 'data', [])
  const byCriteria = keyBy(priorData, ra => ra.criterion_id)
  const criteriaById = keyBy(rubric.criteria, c => c.id)
  const hidePoints = get(rubricAssociation, 'hide_points', false)
  const freeForm = rubric.free_form_criterion_comments

  const onCriteriaChange = id => update => {
    const data = priorData.map(prior => (prior.criterion_id === id ? {...prior, ...update} : prior))

    const ignore = c => (isUndefined(c) ? true : c.ignore_for_scoring)
    const points = data
      .filter(result => !ignore(criteriaById[result.criterion_id]))
      .map(result => get(result, 'points.value', 0))

    onAssessmentChange({
      ...rubricAssessment,
      data,
      score: sum(points)
    })
  }

  // we show the last column for points or comments button
  const showPointsColumn = () => {
    if (isSummary) {
      return false
    }
    if (!hidePoints) {
      return true
    }
    if (assessing && !freeForm) {
      return true
    } // comments button
    return false
  }

  const criteria = rubric.criteria.map(criterion => {
    const assessment = byCriteria[criterion.id]
    return (
      <Criterion
        allowExtraCredit={allowExtraCredit}
        allowSavedComments={!peerReview}
        key={criterion.id}
        assessment={assessment}
        criterion={criterion}
        customRatings={customRatings}
        freeForm={freeForm}
        isSummary={isSummary}
        onAssessmentChange={assessing ? onCriteriaChange(criterion.id) : undefined}
        savedComments={getSavedComments(rubricAssociation, criterion.id)}
        hidePoints={hidePoints}
        hasPointsColumn={showPointsColumn()}
      />
    )
  })

  const possible = rubric.points_possible
  const points = get(rubricAssessment, 'score', possible)
  const total = assessing ? totalAssessingString(points, possible) : totalString(points)
  const hideScoreTotal = get(rubricAssociation, 'hide_score_total') === true
  const noScore = get(rubricAssociation, 'score') === null
  const showTotalPoints = !hidePoints && !hideScoreTotal
  const maxRatings = max(rubric.criteria.map(c => c.ratings.length))
  const minSize = () => {
    if (isSummary || flexWidth) return {}
    else {
      const ratingCorrection = freeForm ? 15 : 7.5 * maxRatings
      return {minWidth: `${15 + ratingCorrection}rem`}
    }
  }

  const headingCells = [
    <th key="TableHeadingCriteria" scope="col" className="rubric-criteria">
      {I18n.t('Criteria')}
    </th>,
    <th key="TableHeadingRatings" scope="col" className="ratings">
      {I18n.t('Ratings')}
    </th>,
    showPointsColumn() ? (
      <th key="TableHeadingPoints" className="rubric-points" scope="col">
        {I18n.t('Pts')}
      </th>
    ) : null
  ]

  const numColumns = 2 + (showPointsColumn() ? 1 : 0)

  return (
    <div className="react-rubric" style={minSize()}>
      <Table caption={<ScreenReaderContent>{rubric.title}</ScreenReaderContent>}>
        <thead>
          {/* This row is a hack to force the fixed layout to render as if the title does not exist */}
          <tr style={{visibility: 'collapse'}}>{headingCells}</tr>
          <tr>
            <th colSpan={numColumns} scope="colgroup" className="rubric-title">
              {rubric.title}
            </th>
          </tr>
          <tr>{headingCells}</tr>
        </thead>
        <tbody className="criterions">
          {criteria}
          {showTotalPoints && (
            <tr>
              <td colSpan={numColumns}>
                <Flex justifyItems="end">
                  <Flex.Item data-selenium="rubric_total">
                    {hideScoreTotal || noScore ? null : total}
                  </Flex.Item>
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
  rubricAssessment: props => {
    const shape = PropTypes.shape(rubricAssessmentShape)
    const rubricAssessment = props.onAssessmentChange ? shape.isRequired : shape
    return PropTypes.checkPropTypes({rubricAssessment}, props, 'prop', 'Rubric')
  },
  rubricAssociation: PropTypes.shape(rubricAssociationShape),
  isSummary: PropTypes.bool,
  flexWidth: PropTypes.bool
}

Rubric.defaultProps = {
  allowExtraCredit: false,
  customRatings: [],
  onAssessmentChange: null,
  rubricAssessment: null,
  rubricAssociation: {},
  isSummary: false,
  flexWidth: false
}

export default Rubric
