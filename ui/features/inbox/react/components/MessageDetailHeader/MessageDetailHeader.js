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

import React from 'react'
import PropTypes from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconMoreLine, IconReplyLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'
import {Tooltip} from '@instructure/ui-tooltip'
import I18n from 'i18n!conversations_2'

export const MessageDetailHeader = ({...props}) => {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          level: 'h4',
          as: 'h3',
          datatestId: 'message-detail-header-mobile'
        },
        desktop: {
          level: 'h3',
          as: 'h3',
          datatestId: 'message-detail-header-desktop'
        }
      }}
      render={responsiveProps => (
        <Flex padding="small">
          <Flex.Item shouldGrow shouldShrink>
            <Heading
              level={responsiveProps.level}
              as={responsiveProps.as}
              data-testid={responsiveProps.datatestId}
            >
              {props.text}
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <Tooltip renderTip={I18n.t('Reply')} on={['hover', 'focus']}>
              <IconButton
                margin="0 x-small 0 0"
                screenReaderLabel={I18n.t('Reply')}
                onClick={() => props.onReply()}
                withBackground={false} withBorder={false}
              >
                <IconReplyLine />
              </IconButton>
            </Tooltip>
          </Flex.Item>
          <Flex.Item>
            <Menu
              placement="bottom"
              trigger={
                <Tooltip renderTip={I18n.t('More options')} on={['hover', 'focus']}>
                  <IconButton 
                    margin="0 x-small 0 0"
                    screenReaderLabel={I18n.t('More options')}
                    withBackground={false}
                    withBorder={false}>
                    <IconMoreLine />
                  </IconButton>
                </Tooltip>
              }
            >
              <Menu.Item value="reply-all" onSelect={() => props.onReplyAll()}>
                {I18n.t('Reply All')}
              </Menu.Item>
              <Menu.Item value="forward">{I18n.t('Forward')}</Menu.Item>
              <Menu.Item value="star">{I18n.t('Star')}</Menu.Item>
              <Menu.Item value="delete">{I18n.t('Delete')}</Menu.Item>
            </Menu>
          </Flex.Item>
          <Flex.Item />
        </Flex>
      )}
    />
  )
}

MessageDetailHeader.propTypes = {
  text: PropTypes.string,
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func
}

MessageDetailHeader.defaultProps = {
  text: null
}
