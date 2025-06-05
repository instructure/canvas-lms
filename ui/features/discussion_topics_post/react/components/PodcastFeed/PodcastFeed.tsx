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
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconRssLine} from '@instructure/ui-icons'
import React from 'react'

const I18n = createI18nScope('discussion_posts')

interface PodcastFeedProps {
  /**
   * Link to discussions RSS feed
   */
  linkUrl: string
  isMobile?: boolean
}

export const PodcastFeed: React.FC<PodcastFeedProps> = ({...props}) => {
  return (
    <span className="discussion-podcast-feed">
      <Button
        display={props.isMobile ? 'block' : 'inline-block'}
        renderIcon={<IconRssLine />}
        href={props.linkUrl}
        data-testid="post-rssfeed"
      >
        {I18n.t('Topic: Podcast Feed')}
      </Button>
    </span>
  )
}
