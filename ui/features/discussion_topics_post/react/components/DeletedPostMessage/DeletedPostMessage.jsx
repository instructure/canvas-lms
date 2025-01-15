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
import {responsiveQuerySizes} from '../../utils'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('discussion_posts')

export function DeletedPostMessage({deleterName, deletedTimingDisplay, children}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          timestampTextSize: 'x-small',
        },
        desktop: {
          timestampTextSize: 'small',
        },
      }}
    >
      {({timestampTextSize}, matches) => (
        <View
          as="div"
          margin={`0 0 0 ${matches.includes('desktop') ? 'xx-large' : '0'}`}
          padding="0 0 0 xx-small"
          data-deletedpost="true"
        >
          <View as="div" margin="0 0 medium 0">
            <View as="div">
              <Text weight="bold">
                {deleterName
                  ? I18n.t('Deleted by %{deleterName}', {deleterName})
                  : I18n.t('Deleted')}
              </Text>
            </View>
            {deletedTimingDisplay && (
              <View as="div">
                <Text size={timestampTextSize}>
                  {I18n.t('Deleted %{deletedTimingDisplay}', {deletedTimingDisplay})}
                </Text>
              </View>
            )}
          </View>

          {children}
          <hr
            style={{
              borderColor: '#E8EAEC',
              width: matches.includes('mobile') && '100vw',
              marginLeft: matches.includes('mobile') && '-5.75rem',
            }}
          />
        </View>
      )}
    </Responsive>
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
   * Display text for the deleted time.
   */
  deletedTimingDisplay: PropTypes.string.isRequired,
}

export default DeletedPostMessage
