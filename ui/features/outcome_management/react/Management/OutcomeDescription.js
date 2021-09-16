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
import I18n from 'i18n!OutcomeManagement'
import PropTypes from 'prop-types'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const OutcomeDescription = ({description, friendlyDescription, truncated}) => {
  const {friendlyDescriptionFF, isStudent} = useCanvasContext()
  const shouldShowFriendlyDescription = friendlyDescriptionFF && friendlyDescription
  let fullDescription = description
  let truncatedDescription = stripHtmlTags(fullDescription || '')
  if (shouldShowFriendlyDescription && (!description || isStudent)) {
    fullDescription = truncatedDescription = friendlyDescription
  }
  const shouldShowFriendlyDescriptionSection =
    !truncated &&
    shouldShowFriendlyDescription &&
    !isStudent &&
    truncatedDescription !== friendlyDescription

  if (!description && !friendlyDescription) return null

  return (
    <View>
      {truncated && truncatedDescription && (
        <View as="div" padding="0 small 0 0" data-testid="description-truncated">
          <PresentationContent>
            <div
              data-testid="description-truncated-content"
              style={{
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis'
              }}
            >
              {truncatedDescription}
            </div>
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
          >
            <Text>{friendlyDescription}</Text>
          </View>
        </>
      )}
      {!truncated && fullDescription && (
        <View
          as="div"
          padding="0 small 0 0"
          data-testid="description-expanded"
          dangerouslySetInnerHTML={{__html: fullDescription}}
        />
      )}
    </View>
  )
}

OutcomeDescription.defaultProps = {
  friendlyDescription: ''
}

OutcomeDescription.propTypes = {
  description: PropTypes.string,
  friendlyDescription: PropTypes.string,
  truncated: PropTypes.bool.isRequired
}

export default OutcomeDescription
