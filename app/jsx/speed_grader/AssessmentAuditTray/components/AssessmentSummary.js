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
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!speed_grader'

import FriendlyDatetime from '../../../shared/FriendlyDatetime'

export default function AssessmentSummary(props) {
  const numberOptions = {precision: 2, strip_insignificant_zeros: true}
  let score = '–'
  if (props.submission.score != null) {
    score = I18n.n(props.submission.score, numberOptions)
  }
  const pointsPossible = I18n.n(props.assignment.pointsPossible, numberOptions)
  const scoreText = I18n.t('%{score}/%{pointsPossible}', {pointsPossible, score})

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
      <FlexItem>
        <Text aria-labelledby="audit-tray-final-grade-label" weight="bold">
          <Text as="div" size="x-large">
            {scoreText}
          </Text>

          <PresentationContent>
            <Text id="audit-tray-final-grade-label" as="div" size="small">
              {I18n.t('Final Grade')}
            </Text>
          </PresentationContent>

          <Text aria-labelledby="audit-tray-posted-date-label" fontStyle="italic" size="small">
            <ScreenReaderContent>{I18n.t('Posted to student')}</ScreenReaderContent>

            <FriendlyDatetime dateTime={props.assignment.gradesPublishedAt} showTime />
          </Text>
        </Text>
      </FlexItem>

      <FlexItem as="div" borderWidth="none none small" margin="small none" padding="none" />

      <FlexItem>
        <Text as="div">{I18n.t('Posted to student')}</Text>

        <Text fontStyle="italic" size="small" weight="bold">
          <FriendlyDatetime dateTime={props.assignment.gradesPublishedAt} showTime />
        </Text>
      </FlexItem>
    </Flex>
  )
}

AssessmentSummary.propTypes = {
  assignment: shape({
    gradesPublishedAt: string,
    pointsPossible: number
  }).isRequired,
  submission: shape({
    score: number
  }).isRequired
}
