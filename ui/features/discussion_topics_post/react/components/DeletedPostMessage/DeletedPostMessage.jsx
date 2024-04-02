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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export function DeletedPostMessage({...props}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          deletedByTextSize: 'small',
          timestampTextSize: 'x-small',
        },
        desktop: {
          deletedByTextSize: 'medium',
          timestampTextSize: 'small',
        },
      }}
      render={responsiveProps => (
        <View as="div" margin="0 0 0 small" padding="0 0 0 xx-small" data-deletedpost="true">
          {props.deleterName && (
            <View as="div">
              <Text size={responsiveProps.deletedByTextSize} weight="bold">
                {I18n.t('Deleted by %{deleterName}', {deleterName: props.deleterName})}
              </Text>
            </View>
          )}
          <Text
            size={
              props.deleterName
                ? responsiveProps.timestampTextSize
                : responsiveProps.deletedByTextSize
            }
            weight={props.deleterName ? undefined : 'bold'}
          >
            {I18n.t('Deleted %{deletedTimingDisplay}', {
              deletedTimingDisplay: props.deletedTimingDisplay,
            })}
          </Text>
          {props.children}
        </View>
      )}
    />
  )
}

DeletedPostMessage.propTypes = {
  /**
   * Children to be directly rendered below the PostMessage
   */
  children: PropTypes.node,
  /**
   * Display name for the deleter of the message
   */
  deleterName: PropTypes.string,
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay: PropTypes.string.isRequired,
  /**
   * Display text for the deleted time.
   */
  deletedTimingDisplay: PropTypes.string.isRequired,
}

export default DeletedPostMessage
