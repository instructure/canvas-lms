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
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import {useScope as useI18nScope} from '@canvas/i18n'
import {get, isUndefined, keyBy, max, sum} from 'lodash'
import PropTypes from 'prop-types'
import React, {useEffect, useRef, useState} from 'react'
import Criterion from './Criterion'
import {getSavedComments} from './helpers'
import {roundIfWhole} from './Points'
import {rubricAssessmentShape, rubricAssociationShape, rubricShape} from './types'

const I18n = useI18nScope('edit_rubricRubric')

// be a little responsive about minimum widths of columns in the rubric table
const MIN_WIDTH_PERCENT = 20
const MIN_WIDTH_PIXELS = 95

const totalString = score =>
  I18n.t('Total Points: %{total}', {
    total: I18n.toNumber(score, {precision: 2, strip_insignificant_zeros: true}),
  })

const totalAssessingString = (score, possible) =>
  I18n.t('Total Points: %{total} out of %{possible}', {
    total: roundIfWhole(score),
    possible: I18n.toNumber(possible, {precision: 2, strip_insignificant_zeros: true}),
  })

// This is a gross hack to make sure the first row in the table is of the eventual columns
// that we want to render, so that they will autosize properly. If we don't do this, then
// what would otherwise be the first row spans all the columns, and that screws up the
// width computations of the entire rest of the table, for a reason I don't understand.
const HiddenTableRow = ({children}) => <tr style={{visibility: 'collapse'}}>{children}</tr>
HiddenTableRow.displayName = 'Row'

const Rubric = props => {
  const {
    allowExtraCredit,
    customRatings,
    onAssessmentChange,
    rubric,
    rubricAssessment,
    rubricAssociation,
    isSummary,
    flexWidth,
  } = props

  const tableRef = useRef()
  const [narrowColWidths, setNarrowColWidths] = useState(undefined)

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
      score: sum(points),
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
    <Table.ColHeader id="table-heading-criteria" key="TableHeadingCriteria" width={narrowColWidths}>
      {I18n.t('Criteria')}
    </Table.ColHeader>,
    <Table.ColHeader id="table-heading-ratings" key="TableHeadingRatings">
      {I18n.t('Ratings')}
    </Table.ColHeader>,
    showPointsColumn() ? (
      <Table.ColHeader id="table-heading-points" key="TableHeadingPoints" width={narrowColWidths}>
        {I18n.t('Pts')}
      </Table.ColHeader>
    ) : null,
  ]

  const numColumns = 2 + (showPointsColumn() ? 1 : 0)

  // Try to be a little responsive about the column widths so the Criteria column
  // looks reasonable at all times at the expense of other columns. We want to use
  // the ResizeObserver for this, which isn't 100% supported by Canvas browsers quite
  // yet; if it's not available, just give up and things might not look amazing when
  // the Rubric table is too narrow.
  useEffect(() => {
    const table = tableRef.current

    function resizer(entries) {
      const width = entries[0].contentRect.width

      if (width === 0) return // we're not visible or have been shrunk to nothing
      setNarrowColWidths(
        (width * MIN_WIDTH_PERCENT) / 100 > MIN_WIDTH_PIXELS
          ? `${MIN_WIDTH_PERCENT}%`
          : `${MIN_WIDTH_PIXELS}px`
      )
    }

    if (!table || !window.ResizeObserver) return
    const obs = new window.ResizeObserver(resizer)
    obs.observe(table)
    return () => {
      obs.unobserve(table)
    }
  }, [])

  return (
    <div ref={tableRef} className="react-rubric" style={minSize()}>
      <Table caption={rubric.title}>
        <Table.Head>
          <HiddenTableRow>{headingCells}</HiddenTableRow>
          <Table.Row>
            <Table.ColHeader id="rubric-title" colSpan={numColumns}>
              {rubric.title}
            </Table.ColHeader>
          </Table.Row>
          <Table.Row>{headingCells}</Table.Row>
        </Table.Head>
        <Table.Body data-testid="criterions">
          {criteria}
          {showTotalPoints && (
            <Table.Row>
              <Table.Cell colSpan={numColumns}>
                <Flex justifyItems="end">
                  <Flex.Item data-selenium="rubric_total">
                    {hideScoreTotal || noScore ? null : total}
                  </Flex.Item>
                </Flex>
              </Table.Cell>
            </Table.Row>
          )}
        </Table.Body>
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
  flexWidth: PropTypes.bool,
}

Rubric.defaultProps = {
  allowExtraCredit: false,
  customRatings: [],
  onAssessmentChange: null,
  rubricAssessment: null,
  rubricAssociation: {},
  isSummary: false,
  flexWidth: false,
}

export default Rubric
