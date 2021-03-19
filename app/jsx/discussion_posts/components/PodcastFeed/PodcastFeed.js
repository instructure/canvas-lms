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

import I18n from 'i18n!conversations_2'
import PropTypes from 'prop-types'
import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {IconRssLine} from '@instructure/ui-icons'

export const PodcastFeed = ({...props}) => {
  return (
    <Button
      color="secondary"
      margin="xx-small"
      renderIcon={IconRssLine}
      href={props.linkUrl}
      data-testid="post-rssfeed"
    >
      {I18n.t('Topic: Podcast Feed')}
    </Button>
  )
}

PodcastFeed.propTypes = {
  /**
   * Link to discussions RSS feed
   */
  linkUrl: PropTypes.string.isRequired
}
