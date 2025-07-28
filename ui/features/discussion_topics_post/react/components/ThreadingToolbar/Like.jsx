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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {IconLikeLine, IconLikeSolid} from '@instructure/ui-icons'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'

const I18n = createI18nScope('discussion_posts')

export function Like({...props}) {
  function icon() {
    if (props.isLiked)
      return (
        <>
          <IconLikeSolid data-testid="liked-icon" size="x-small" />
          <ScreenReaderContent>
            {I18n.t('Unlike post from %{author}', {author: props.authorName})}
          </ScreenReaderContent>
        </>
      )
    else
      return (
        <>
          <IconLikeLine data-testid="not-liked-icon" size="x-small" />
          <ScreenReaderContent>
            {I18n.t('Like post from %{author}', {author: props.authorName})}
          </ScreenReaderContent>
        </>
      )
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          isMobile: true,
        },
        desktop: {
          isMobile: false,
        },
      }}
      render={responsiveProps => (
        <View className="discussion-like-btn">
          <Link
            isWithinText={false}
            as="button"
            onClick={props.onClick}
            data-testid="like-button"
            data-action-state={props.isLiked ? 'unlikeButton' : 'likeButton'}
            interaction={props.interaction}
          >
            <PresentationContent>
              <Text weight="bold" data-testid="like-count" size="medium">
                {icon()}
                {props.likeCount > 0 && <View margin="0 0 0 xx-small">{props.likeCount}</View>}
                {!responsiveProps.isMobile &&
                  !props.isSplitScreenView &&
                  ` ${I18n.t(
                    {
                      zero: 'Like',
                      one: 'Like',
                      other: 'Likes',
                    },
                    {count: props.likeCount},
                  )}`}
              </Text>
            </PresentationContent>
            <ScreenReaderContent>
              {I18n.t('Like count: %{count}', {count: props.likeCount})}
            </ScreenReaderContent>
          </Link>
        </View>
      )}
    />
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
  delimiterKey: PropTypes.string.isRequired,
  /**
   * Specifies if the interaction with Like is enabled, disabled, or readonly
   */
  interaction: PropTypes.string,
  /**
   * Name of the author of the post being liked
   */
  authorName: PropTypes.string.isRequired,

  isSplitScreenView: PropTypes.bool,
}
