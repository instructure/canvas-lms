/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!discussion_posts'
import PropTypes from 'prop-types'
import React from 'react'
import {CondensedButton} from '@instructure/ui-buttons'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'

export function Like({...props}) {
  return (
    <CondensedButton
      renderIcon={
        props.isLiked ? (
          <IconLikeSolid data-testid="liked-icon" />
        ) : (
          <IconLikeLine data-testid="not-liked-icon" />
        )
      }
      onClick={props.onClick}
      withBackground={false}
      color="primary"
      data-testid="like-button"
    >
      <ScreenReaderContent>
        {props.isLiked ? I18n.t('Unlike post') : I18n.t('Like post')}
      </ScreenReaderContent>
      {props.likeCount > 0 && (
        <>
          <PresentationContent>{props.likeCount}</PresentationContent>
          <ScreenReaderContent>
            {I18n.t('Like count: %{count}', {count: props.likeCount})}
          </ScreenReaderContent>
        </>
      )}
    </CondensedButton>
  )
}

Like.propTypes = {
  /**
   * Behavior when clicking the like button
   */
  onClick: PropTypes.func.isRequired,
  /**
   * Whether or not the post has been liked. Determines
   * which version of the icon and helper text is displayed
   */
  isLiked: PropTypes.bool.isRequired,
  /**
   * Number of likes for the post. Displays nothing if
   * less than one
   */
  likeCount: PropTypes.number.isRequired,
  /**
   * Key consumed by ThreadingToolbar's InlineList
   */
  delimiterKey: PropTypes.string.isRequired
}
