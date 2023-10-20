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

import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconRssLine} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('discussion_posts')

export const PodcastFeed = ({...props}) => {
  return (
    <span className="discussion-podcast-feed">
      <Button
        color="secondary"
        display={props.responsiveProps?.display}
        renderIcon={IconRssLine}
        href={props.linkUrl}
        data-testid="post-rssfeed"
      >
        <Text weight="bold" size={props.responsiveProps?.textSize}>
          {I18n.t('Topic: Podcast Feed')}
        </Text>
      </Button>
    </span>
  )
}

PodcastFeed.propTypes = {
  /**
   * Link to discussions RSS feed
   */
  linkUrl: PropTypes.string.isRequired,
  responsiveProps: PropTypes.object,
}
