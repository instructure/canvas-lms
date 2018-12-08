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
import {number, shape, string} from 'prop-types'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Pill from '@instructure/ui-elements/lib/components/Pill'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!speed_grader'

import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import {overallAnonymityStates} from '../AuditTrailHelpers'
import * as propTypes from './AuditTrail/propTypes'

function getOverallAnonymityLabel(overallAnonymity) {
  switch (overallAnonymity) {
    case overallAnonymityStates.FULL: {
      return I18n.t('Anonymous On')
    }
    case overallAnonymityStates.PARTIAL: {
      return I18n.t('Partially Anonymous')
    }
    default: {
      return I18n.t('Anonymous Off')
    }
  }
}

export default function AssessmentSummary(props) {
  const {anonymityDate, assignment, overallAnonymity, submission} = props

  const numberOptions = {precision: 2, strip_insignificant_zeros: true}
  let score = '–'
  if (submission.score != null) {
    score = I18n.n(submission.score, numberOptions)
  }
  const pointsPossible = I18n.n(assignment.pointsPossible, numberOptions)
  const scoreText = I18n.t('%{score}/%{pointsPossible}', {pointsPossible, score})

  const overallAnonymityLabel = getOverallAnonymityLabel(overallAnonymity)
  const overallAnonymityLabelColor =
    overallAnonymity === overallAnonymityStates.FULL ? 'primary' : 'danger'

  let overallAnonymityDescription
  if (anonymityDate == null) {
    overallAnonymityDescription = I18n.t('Anonymous was never turned on')
  } else {
    overallAnonymityDescription = (
      <FriendlyDatetime dateTime={anonymityDate} prefix={I18n.t('As of')} showTime />
    )
  }

  return (
    <Flex
      as="section"
      background="default"
      borderRadius="medium"
      borderWidth="small"
      direction="column"
      justifyItems="center"
      padding="small"
      textAlign="center"
    >
      <FlexItem id="audit-tray-final-grade">
        <Text aria-labelledby="audit-tray-final-grade-label" weight="bold">
          <Text as="div" size="x-large">
            {scoreText}
          </Text>

          <PresentationContent>
            <Text id="audit-tray-final-grade-label" as="div" size="small">
              {I18n.t('Final Grade')}
            </Text>
          </PresentationContent>

          <Text fontStyle="italic" size="small">
            <FriendlyDatetime dateTime={props.finalGradeDate} showTime />
          </Text>
        </Text>
      </FlexItem>

      <FlexItem as="div" borderWidth="none none small" margin="small none" padding="none" />

      <FlexItem id="audit-tray-grades-posted">
        <Text as="div">{I18n.t('Posted to student')}</Text>

        <Text as="div" fontStyle="italic" size="small" weight="bold">
          <FriendlyDatetime dateTime={props.assignment.gradesPublishedAt} showTime />
        </Text>
      </FlexItem>

      <FlexItem>
        <Pill
          as="div"
          id="audit-tray-overall-anonymity-label"
          margin="x-small"
          text={overallAnonymityLabel}
          variant={overallAnonymityLabelColor}
        />

        <Text
          as="div"
          id="audit-tray-overall-anonymity-description"
          fontStyle="italic"
          size="small"
          weight="bold"
        >
          {overallAnonymityDescription}
        </Text>
      </FlexItem>
    </Flex>
  )
}

AssessmentSummary.propTypes = {
  anonymityDate: propTypes.anonymityDate,
  assignment: shape({
    gradesPublishedAt: string,
    pointsPossible: number
  }).isRequired,
  finalGradeDate: propTypes.finalGradeDate.isRequired,
  overallAnonymity: propTypes.overallAnonymity.isRequired,
  submission: shape({
    score: number
  }).isRequired
}

AssessmentSummary.defaultProps = {
  anonymityDate: null
}
