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
import Dialog from '@instructure/ui-a11y/lib/components/Dialog'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Button from '@instructure/ui-buttons/lib/components/Button'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconOutcomes from '@instructure/ui-icons/lib/Line/IconOutcomes'
import Modal, { ModalHeader, ModalBody } from '@instructure/ui-overlays/lib/components/Modal'
import I18n from 'i18n!edit_rubric'

import numberHelper from 'jsx/shared/helpers/numberHelper'
import { assessmentShape, criterionShape } from './types'
import CommentButton from './CommentButton'
import Comments, { CommentText } from './Comments'
import Points from './Points'
import Ratings from './Ratings'

const OutcomeIcon = () => (
  <span>
    <IconOutcomes />&nbsp;
    <ScreenReaderContent>{I18n.t('This criterion is linked to a Learning Outcome')}</ScreenReaderContent>
  </span>
)

const LongDescription = ({ showLongDescription }) => (
  // eslint-disable-next-line jsx-a11y/anchor-is-valid
  <Button fluidWidth variant="link" onClick={() => showLongDescription()}>
    <Text size="x-small">{I18n.t('view longer description')}</Text>
  </Button>
)
LongDescription.propTypes = {
  showLongDescription: PropTypes.func.isRequired
}

const LongDescriptionDialog = ({ open, close, longDescription }) => {
  const modalHeader = I18n.t('Criterion Long Description')
  /* eslint-disable react/no-danger */
  return (
    <Modal
       open={open}
       onDismiss={close}
       size="medium"
       label={modalHeader}
       shouldCloseOnDocumentClick
    >
      <ModalHeader>
        <CloseButton
          placement="end"
          offset="medium"
          variant="icon"
          onClick={close}
        >
          Close
        </CloseButton>
        <Heading>{modalHeader}</Heading>
      </ModalHeader>
      <ModalBody>
        <Text lineHeight="double">
          <div dangerouslySetInnerHTML={{ __html: longDescription }} />
        </Text>
      </ModalBody>
    </Modal>
  )
  /* eslint-enable react/no-danger */
}
LongDescriptionDialog.propTypes = {
  close: PropTypes.func.isRequired,
  longDescription: PropTypes.string.isRequired,
  open: PropTypes.bool
}
LongDescriptionDialog.defaultProps = {
  open: false
}

const Threshold = ({ threshold }) => (
  <Text size="x-small" weight="normal">
    {
      I18n.t('threshold: %{pts}', {
        pts: I18n.toNumber(threshold, { precision: 2, strip_insignificant_zeros: true } )
      })
    }
  </Text>
)
Threshold.defaultProps = { threshold: null }
Threshold.propTypes = { threshold: PropTypes.number }

export default class Criterion extends React.Component {
  state = {}

  closeModal = () => { this.setState({ dialogOpen: false }) }

  openModal = () => {
    this.setState({ dialogOpen: true })
  }

  render () {
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
      hasPointsColumn
    } = this.props
    const { dialogOpen } = this.state
    const isOutcome = criterion.learning_outcome_id !== undefined
    const useRange = criterion.criterion_use_range
    const ignoreForScoring = criterion.ignore_for_scoring
    const assessing = onAssessmentChange !== null && assessment !== null
    const updatePoints = (tier) => {
      // Tier will be a string if entered directly from the point input field. In those situations,
      // the tier description and ID will be added based off the point value upon saving in the
      // rubric_association model
      if (typeof tier === "string") {
        tier = _.find(criterion.ratings, (rating) => rating.points.toString() === tier) || {points: tier}
      }
      const text = tier.points
      const value = numberHelper.parse(text)
      const valid = !Number.isNaN(value)
      onAssessmentChange({
        points: { text, valid, value: valid ? value : undefined },
        description: tier.description,
        id: tier.id
      })
    }
    const onPointChange = assessing ? updatePoints : undefined

    const pointsPossible = criterion.points
    const pointsElement = () => (
      (!hidePoints && !ignoreForScoring) && (
        <Points
          key="points"
          allowExtraCredit={!isOutcome || allowExtraCredit}
          assessing={assessing}
          assessment={assessment}
          onPointChange={onPointChange}
          pointsPossible={pointsPossible}
        />
      )
    )

    const pointsComment = () => (
      <CommentText key="comment" assessment={assessment} weight="light" />
    )

    const summaryFooter = () => [
      pointsComment(),
      pointsElement()
    ]

    const commentRating = (
      <Comments
        allowSaving={allowSavedComments}
        editing={assessing}
        assessment={assessment}
        footer={isSummary ? pointsElement() : null}
        large={freeForm}
        savedComments={savedComments}
        setSaveLater={(saveCommentsForLater) => onAssessmentChange({ saveCommentsForLater })}
        setComments={(comments) => onAssessmentChange({ comments })}
      />
    )

    const hasComments = (_.get(assessment, 'comments') || '').length > 0
    const editingComments = hasComments || freeForm || _.get(assessment, 'editComments', false)
    const commentFocus = _.get(assessment, 'commentFocus', false)

    const ratingsFooter = () => {
      if (editingComments) {
        return commentFocus ? <Dialog open>{commentRating}</Dialog> : commentRating
      }
    }

    const ratings = freeForm ? commentRating : (
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

    const editComments = () => onAssessmentChange({
      commentFocus: true,
      editComments: true
    })
    const commentButton = assessment !== null ? (
      <CommentButton onClick={editComments} />
    ) : null

    const longDescription = criterion.long_description
    const threshold = criterion.mastery_points

    return (
      <tr className="rubric-criterion">
        <th scope="row" className="description-header">
          <div className="description react-rubric-cell">
            {isOutcome ? <OutcomeIcon /> : ''}
            <Text size="small" weight="normal">
              {criterion.description}
            </Text>
          </div>
          <div className="long-description">
            {
              longDescription !== "" ? (
                <LongDescription showLongDescription={this.openModal} />
              ) : null
            }
            <LongDescriptionDialog
              close={this.closeModal}
              longDescription={longDescription}
              open={dialogOpen}
              />
          </div>
          {
            !(hidePoints || _.isNil(threshold)) ? <Threshold threshold={threshold} /> : null
          }
        </th>
        <td className="ratings">
          {ratings}
        </td>
        {
          hasPointsColumn && (
            <td className="criterion_points">
              {pointsElement()}
              {assessing && !freeForm && !editingComments ? commentButton : null}
            </td>
          )
        }
      </tr>
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
  hasPointsColumn: PropTypes.bool
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
  hasPointsColumn: true
}
