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
import CommentInput from './CommentInput'
import FreeFormComments from './FreeFormComments'
import Points from './Points'
import Ratings from './Ratings'

const Comments = ({ assessment, freeForm }) => (
  <div className={freeForm ? 'rubric-freeform' : ''}>
    <Text size="x-small" weight={freeForm ? 'normal' : 'light'}>
      {
        assessment && assessment.comments_html ?
          // eslint-disable-next-line react/no-danger
          <div dangerouslySetInnerHTML={{ __html: assessment.comments_html }} />
          : assessment && assessment.comments
      }
    </Text>
  </div>
)
Comments.propTypes = {
  assessment: PropTypes.shape(assessmentShape).isRequired,
  freeForm: PropTypes.bool.isRequired
}

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
         <Text lineHeight="double">{longDescription}</Text>
       </ModalBody>
    </Modal>
  )
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
  <Text size="x-small">
    {
      I18n.t('threshold: %{pts}', {
        pts: I18n.toNumber(threshold, { precision: 1 } )
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
      assessment,
      criterion,
      freeForm,
      onAssessmentChange,
      savedComments
    } = this.props
    const { dialogOpen } = this.state
    const isOutcome = criterion.learning_outcome_id !== undefined
    const assessing = onAssessmentChange !== null
    const updatePoints = (text) => {
      let points = numberHelper.parse(text)
      if(Number.isNaN(points)) { points = null }
      onAssessmentChange({
        points,
        pointsText: text.toString()
      })
    }
    const onPointChange = assessing ? updatePoints : undefined
    const showComments = <Comments assessment={assessment} freeForm={freeForm} />
    const editComments = (
      <FreeFormComments
        comments={assessment.comments}
        saveLater={assessment.saveCommentsForLater}
        savedComments={savedComments}
        setSaveLater={(saveCommentsForLater) => onAssessmentChange({ saveCommentsForLater })}
        setComments={(comments) => onAssessmentChange({ comments })}
      />
    )
    const commentView = assessing ? editComments : showComments
    const ratings = freeForm ? commentView : (
      <Ratings
        assessing={assessing}
        tiers={criterion.ratings}
        onPointChange={onPointChange}
        points={assessment.points}
        masteryThreshold={isOutcome ? criterion.mastery_points : criterion.points}
      />
    )

    const finalize = (update) => {
      const common = { commentsOpen: false }
      if (update) {
        onAssessmentChange({ ...common, comments: assessment.partialComments })
      } else {
        onAssessmentChange({ ...common, partialComments: undefined })
      }
    }
    const updateComments = (partialComments) =>
      onAssessmentChange({ partialComments })

    const commentInput = (
      <CommentInput
        comments={assessment.partialComments || assessment.comments}
        description={criterion.description}
        finalize={finalize}
        initialize={() => onAssessmentChange({ commentsOpen: true })}
        open={assessment.commentsOpen}
        setComments={updateComments}
      />
    )

    const points = assessment && assessment.points
    const pointsText = assessment.pointsText
    const pointsPossible = criterion.points
    const longDescription = criterion.long_description
    const threshold = criterion.mastery_points

    return (
      <tr className="rubric-criterion">
        <th scope="row" className="description-header">
          <div className="description container">
            {isOutcome ? <OutcomeIcon /> : ''}
            <Text size="small">
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
            threshold !== undefined ? <Threshold threshold={threshold} /> : null
          }
          {
            (freeForm || assessing) ? null : (
              <div className="assessment-comments">
                <Text size="x-small" weight="normal">{I18n.t('Instructor Comments')}</Text>
                {commentView}
              </div>
            )
          }
        </th>
        <td className="ratings">
          {ratings}
        </td>
        <td>
          <Points
            assessing={assessing}
            onPointChange={onPointChange}
            points={points}
            pointsPossible={pointsPossible}
            pointsText={pointsText}
          />
          {assessing && !freeForm ? commentInput : null}
        </td>
      </tr>
    )
  }
}
Criterion.propTypes = {
  assessment: PropTypes.shape(assessmentShape).isRequired,
  criterion: PropTypes.shape(criterionShape).isRequired,
  freeForm: PropTypes.bool.isRequired,
  onAssessmentChange: PropTypes.func,
  savedComments: PropTypes.arrayOf(PropTypes.string)
}
Criterion.defaultProps = {
  onAssessmentChange: null,
  savedComments: []
}
