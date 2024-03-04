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
import PropTypes from 'prop-types'
import _ from 'lodash'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Dialog} from '@instructure/ui-dialog'
import {CloseButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import {IconOutcomesLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {useScope as useI18nScope} from '@canvas/i18n'

import numberHelper from '@canvas/i18n/numberHelper'
import {assessmentShape, criterionShape} from './types'
import CommentButton from './CommentButton'
import Comments, {CommentText} from './Comments'
import Points from './Points'
import Ratings from './Ratings'

const I18n = useI18nScope('edit_rubricCriterion')

const OutcomeIcon = () => (
  <span>
    <IconOutcomesLine />
    &nbsp;
    <ScreenReaderContent>
      {I18n.t('This criterion is linked to a Learning Outcome')}
    </ScreenReaderContent>
  </span>
)

const LongDescription = ({showLongDescription}) => (
  <Link onClick={() => showLongDescription()} display="block" textAlign="start">
    <Text size="x-small">{I18n.t('view longer description')}</Text>
  </Link>
)
LongDescription.propTypes = {
  showLongDescription: PropTypes.func.isRequired,
}

const LongDescriptionDialog = ({open, close, longDescription}) => {
  const modalHeader = I18n.t('Criterion Long Description')
  return (
    <Modal
      open={open}
      onDismiss={close}
      size="medium"
      label={modalHeader}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={close}
          screenReaderLabel="\n          Close\n        "
        />
        <Heading>{modalHeader}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text lineHeight="double" wrap="break-word">
          <div dangerouslySetInnerHTML={{__html: longDescription}} />
        </Text>
      </Modal.Body>
    </Modal>
  )
}
LongDescriptionDialog.propTypes = {
  close: PropTypes.func.isRequired,
  longDescription: PropTypes.string.isRequired,
  open: PropTypes.bool,
}
LongDescriptionDialog.defaultProps = {
  open: false,
}

const Threshold = ({threshold}) => (
  <Text size="x-small" weight="normal">
    {I18n.t('threshold: %{pts}', {
      pts: I18n.toNumber(threshold, {precision: 2, strip_insignificant_zeros: true}),
    })}
  </Text>
)
Threshold.defaultProps = {threshold: null}
Threshold.propTypes = {threshold: PropTypes.number}

export default class Criterion extends React.Component {
  static displayName = 'Row'

  state = {}

  closeModal = () => {
    this.setState({dialogOpen: false})
  }

  openModal = () => {
    this.setState({dialogOpen: true})
  }

  render() {
    const {
      allowExtraCredit,
      allowSavedComments,
      assessment,
      criterion,
      customRatings,
      freeForm,
      onAssessmentChange,
      savedComments,
      isSummary,
      hidePoints,
      hasPointsColumn,
    } = this.props
    const {dialogOpen} = this.state
    const isOutcome = criterion.learning_outcome_id !== undefined
    const useRange = criterion.criterion_use_range
    const ignoreForScoring = criterion.ignore_for_scoring
    const assessing = onAssessmentChange !== null && assessment !== null
    const updatePoints = (tier, isSelected) => {
      // Tier will be a string if entered directly from the point input field. In those situations,
      // the tier description and ID will be added based off the point value upon saving in the
      // rubric_association model
      if (typeof tier === 'string') {
        tier = _.find(criterion.ratings, rating => rating.points.toString() === tier) || {
          points: tier,
        }
      }
      const text = tier.points.toString()
      const value = numberHelper.parse(text)
      const valid = !Number.isNaN(value)
      if (isSelected) {
        onAssessmentChange({
          points: {text: '', valid: true},
        })
      } else {
        onAssessmentChange({
          points: {text, valid, value: valid ? value : undefined},
          description: tier.description,
          id: tier.id,
        })
      }
    }
    const onPointChange = assessing ? updatePoints : undefined

    const pointsPossible = criterion.points
    const pointsElement = () =>
      !hidePoints &&
      !ignoreForScoring && (
        <Points
          key="points"
          allowExtraCredit={!isOutcome || allowExtraCredit}
          assessing={assessing}
          assessment={assessment}
          onPointChange={onPointChange}
          pointsPossible={pointsPossible}
        />
      )

    const pointsComment = () => (
      <CommentText key="comment" assessment={assessment} weight="normal" />
    )

    const summaryFooter = () => [pointsComment(), pointsElement()]

    const commentRating = (
      <Comments
        allowSaving={allowSavedComments}
        editing={assessing}
        assessment={assessment}
        footer={isSummary ? pointsElement() : null}
        large={freeForm}
        savedComments={savedComments}
        setSaveLater={saveCommentsForLater => onAssessmentChange({saveCommentsForLater})}
        setComments={comments => onAssessmentChange({comments})}
      />
    )

    const hasComments = (_.get(assessment, 'comments') || '').length > 0
    const editingComments = hasComments || freeForm || _.get(assessment, 'editComments', false)
    const commentFocus = _.get(assessment, 'commentFocus', false)

    const ratingsFooter = () => {
      if (editingComments) {
        return commentFocus ? <Dialog open={true}>{commentRating}</Dialog> : commentRating
      }
    }

    const ratings = freeForm ? (
      commentRating
    ) : (
      <Ratings
        assessing={assessing}
        customRatings={customRatings}
        footer={isSummary ? summaryFooter() : ratingsFooter()}
        tiers={criterion.ratings}
        onPointChange={onPointChange}
        points={_.get(assessment, 'points.value')}
        selectedRatingId={_.get(assessment, 'id')}
        pointsPossible={pointsPossible}
        defaultMasteryThreshold={isOutcome ? criterion.mastery_points : criterion.points}
        isSummary={isSummary}
        useRange={useRange}
        hidePoints={hidePoints}
      />
    )

    const editComments = () =>
      onAssessmentChange({
        commentFocus: true,
        editComments: true,
      })
    const commentButton = assessment !== null ? <CommentButton onClick={editComments} /> : null

    const longDescription = criterion.long_description
    const threshold = criterion.mastery_points

    return (
      <Table.Row data-testid="rubric-criterion">
        <Table.RowHeader>
          <div className="description react-rubric-cell">
            {isOutcome ? <OutcomeIcon /> : ''}
            <Text size="small" weight="normal">
              {criterion.description}
            </Text>
          </div>
          <div className="long-description">
            {longDescription?.trim() ? (
              <LongDescription showLongDescription={this.openModal} />
            ) : null}
            <LongDescriptionDialog
              close={this.closeModal}
              longDescription={longDescription}
              open={dialogOpen}
            />
          </div>
          {!(hidePoints || _.isNil(threshold)) ? <Threshold threshold={threshold} /> : null}
        </Table.RowHeader>
        <Table.Cell>{ratings}</Table.Cell>
        {hasPointsColumn && (
          <Table.Cell data-testid="criterion-points">
            {pointsElement()}
            {assessing && !freeForm && !editingComments ? commentButton : null}
          </Table.Cell>
        )}
      </Table.Row>
    )
  }
}
Criterion.propTypes = {
  allowExtraCredit: PropTypes.bool,
  allowSavedComments: PropTypes.bool,
  assessment: PropTypes.shape(assessmentShape),
  customRatings: PropTypes.arrayOf(PropTypes.object),
  criterion: PropTypes.shape(criterionShape).isRequired,
  freeForm: PropTypes.bool.isRequired,
  onAssessmentChange: PropTypes.func,
  savedComments: PropTypes.arrayOf(PropTypes.string),
  isSummary: PropTypes.bool,
  hidePoints: PropTypes.bool,
  hasPointsColumn: PropTypes.bool,
}

Criterion.defaultProps = {
  allowExtraCredit: false,
  allowSavedComments: true,
  assessment: null,
  customRatings: [],
  onAssessmentChange: null,
  savedComments: [],
  isSummary: false,
  hidePoints: false,
  hasPointsColumn: true,
}
