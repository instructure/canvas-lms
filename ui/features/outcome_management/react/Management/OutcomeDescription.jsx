/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import ProficiencyCalculation from '../MasteryCalculation/ProficiencyCalculation'
import {prepareRatings} from '@canvas/outcomes/react/hooks/useRatings'
import Ratings from './Ratings'
import {ratingsShape} from './shapes'

const I18n = useI18nScope('OutcomeManagement')

const OutcomeDescription = ({
  description,
  friendlyDescription,
  truncated,
  calculationMethod,
  calculationInt,
  masteryPoints,
  ratings,
  setShouldExpand,
  isEnhanced,
}) => {
  const {friendlyDescriptionFF, isStudent, accountLevelMasteryScalesFF} = useCanvasContext()
  const shouldShowFriendlyDescription = friendlyDescriptionFF && friendlyDescription
  let fullDescription = description
  let truncatedDescription = stripHtmlTags(fullDescription || '')
  let fullDescriptionIsFriendlyDescription = false
  if (shouldShowFriendlyDescription && (!description || isStudent)) {
    fullDescription = truncatedDescription = friendlyDescription
    fullDescriptionIsFriendlyDescription = true
  }
  const shouldShowFriendlyDescriptionSection =
    !truncated &&
    shouldShowFriendlyDescription &&
    !isStudent &&
    truncatedDescription !== friendlyDescription

  if (!description && !friendlyDescription && accountLevelMasteryScalesFF) return null

  // Update handler for TruncateText's onUpdate property
  // isTruncated returns true if description is
  // truncated (contains {...} at the end)
  const onUpdateHandler = isTruncated => {
    setShouldExpand(isTruncated)
  }

  return (
    <View>
      {truncated && truncatedDescription && (
        <View
          as="div"
          padding="0 small 0 0"
          data-testid="description-truncated"
          className={isEnhanced ? 'user_content' : 'user_content unenhanced'}
        >
          <PresentationContent>
            <TruncateText data-testid="description-truncated-content" onUpdate={onUpdateHandler}>
              {truncatedDescription}
            </TruncateText>
          </PresentationContent>
          <ScreenReaderContent>{truncatedDescription}</ScreenReaderContent>
        </View>
      )}
      {shouldShowFriendlyDescriptionSection && (
        <>
          <View
            as="div"
            margin="x-small small 0 0"
            padding="small small x-small small"
            background="secondary"
          >
            <Text weight="bold">{I18n.t('Friendly Description')}</Text>
          </View>
          <View
            as="div"
            margin="0 small 0 0"
            padding="0 small small small"
            background="secondary"
            data-testid="friendly-description-expanded"
            className="user_content"
          >
            <Text wrap="break-word">{friendlyDescription}</Text>
          </View>
        </>
      )}

      {!truncated && fullDescription && !fullDescriptionIsFriendlyDescription && (
        <View
          as="div"
          padding="0 small 0 0"
          data-testid="description-expanded"
          className="user_content"
          dangerouslySetInnerHTML={{__html: fullDescription}}
        />
      )}

      {!truncated && fullDescription && fullDescriptionIsFriendlyDescription && (
        <View
          as="div"
          padding="0 small 0 0"
          data-testid="description-expanded"
          className="user_content"
        >
          <Text wrap="break-word">{fullDescription}</Text>
        </View>
      )}

      {!truncated && !accountLevelMasteryScalesFF && (
        <View>
          <Ratings
            ratings={prepareRatings(ratings)}
            masteryPoints={{
              value: masteryPoints,
              error: null,
            }}
            canManage={false}
          />
          <ProficiencyCalculation
            method={{calculationMethod, calculationInt}}
            individualOutcome="display"
            canManage={false}
          />
        </View>
      )}
    </View>
  )
}

OutcomeDescription.defaultProps = {
  friendlyDescription: '',
  setShouldExpand: () => {},
}

OutcomeDescription.propTypes = {
  description: PropTypes.string,
  calculationMethod: PropTypes.string,
  calculationInt: PropTypes.number,
  masteryPoints: PropTypes.number,
  ratings: ratingsShape,
  friendlyDescription: PropTypes.string,
  truncated: PropTypes.bool.isRequired,
  setShouldExpand: PropTypes.func.isRequired,
  isEnhanced: PropTypes.bool,
}

export default OutcomeDescription
