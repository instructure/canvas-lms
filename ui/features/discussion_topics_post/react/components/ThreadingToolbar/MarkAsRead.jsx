/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import ReadIcon from '@canvas/read-icon'
import UnreadIcon from '@canvas/unread-icon'

const I18n = createI18nScope('discussion_posts')
const markAsReadText = I18n.t('Mark as Read')
const markAsUnreadText = I18n.t('Mark as Unread')

export const MarkAsRead = props => {
  const currentText = props.isRead ? markAsUnreadText : markAsReadText
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          itemSpacing: '0 xx-small 0 0',
          isMobile: true,
        },
        desktop: {
          itemSpacing: 'none',
          isMobile: false,
        },
      }}
      render={responsiveProps => (
        <View
          className="discussion-markAsRead-btn"
          margin={responsiveProps.itemSpacing}
          style={{display: 'inline-flex', alignItems: 'center'}}
        >
          <Link
            isWithinText={false}
            as="button"
            onClick={() => props.onClick()}
            renderIcon={props.isRead ? <UnreadIcon /> : <ReadIcon />}
            data-testid="threading-toolbar-mark-as-read"
            data-action-state={props.isRead ? 'unreadButton' : 'readButton'}
          >
            {!responsiveProps.isMobile && !props.isSplitScreenView && (
              <AccessibleContent alt={currentText}>
                <Text weight="bold" size="medium" style={{alignSelf: 'flex-end'}}>
                  {currentText}
                </Text>
              </AccessibleContent>
            )}
          </Link>
        </View>
      )}
    />
  )
}

MarkAsRead.defaultProps = {
  isRead: true,
  onClick: () => {},
}

MarkAsRead.propTypes = {
  isRead: PropTypes.bool,
  onClick: PropTypes.func,
  isSplitScreenView: PropTypes.bool,
}
