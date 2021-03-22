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
import {Byline} from '@instructure/ui-byline'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

export function DeletedPostMessage({...props}) {
  return (
    <Byline alignContent="top">
      <Text weight="bold">
        {I18n.t('Deleted by %{deleterName}', {deleterName: props.deleterName})}
      </Text>
      <View padding="0 small">
        <Text color="secondary">{props.timingDisplay}</Text>
      </View>
    </Byline>
  )
}

DeletedPostMessage.propTypes = {
  /**
   * Display name for the deleter of the message
   */
  deleterName: PropTypes.string.isRequired,
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay: PropTypes.string.isRequired
}

export default DeletedPostMessage
