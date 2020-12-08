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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {TruncateText} from '@instructure/ui-truncate-text'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {stripHtmlTags} from '../../shared/helpers/stripHtmlTags'

const OutcomeDescription = ({description, withExternalControl, truncate, onClickHandler}) => {
  const [truncateInternal, setTruncateInternal] = useState(true)
  const truncated = withExternalControl ? truncate : truncateInternal
  const textDescription = description ? stripHtmlTags(description) : ''
  const onToggleHandler = () =>
    withExternalControl ? onClickHandler() : setTruncateInternal(prevState => !prevState)
  const onKeyDownHandler = event => [13, 32].includes(event.keyCode) && onToggleHandler()

  if (!description) return null

  return (
    <>
      {truncated && textDescription && (
        <View
          as="div"
          tabIndex="0"
          padding="small xx-small 0 0"
          cursor="pointer"
          role="button"
          data-testid="description-truncated"
          onClick={onToggleHandler}
          onKeyDown={onKeyDownHandler}
        >
          <PresentationContent>
            <TruncateText>{textDescription}</TruncateText>
          </PresentationContent>
          <ScreenReaderContent>{textDescription}</ScreenReaderContent>
        </View>
      )}
      {!truncated && description && (
        <View
          as="div"
          tabIndex="0"
          padding="0"
          cursor="pointer"
          role="button"
          data-testid="description-expanded"
          dangerouslySetInnerHTML={{__html: description}}
          onClick={onToggleHandler}
          onKeyDown={onKeyDownHandler}
        />
      )}
    </>
  )
}

OutcomeDescription.defaultProps = {
  withExternalControl: false
}

OutcomeDescription.propTypes = {
  description: PropTypes.string,
  withExternalControl: PropTypes.bool,
  truncate: PropTypes.bool,
  onClickHandler: PropTypes.func
}

export default OutcomeDescription
