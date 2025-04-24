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

import React from 'react'
import {Button} from '@instructure/ui-buttons'
import {ChildTopic} from '../../../graphql/ChildTopic'
import {getGroupDiscussionUrl} from '../../utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {IconGroupLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import PropTypes from 'prop-types'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'

const I18n = createI18nScope('discussion_posts')

export const GroupsMenu = ({...props}) => {
  const menuItems = props.childTopics?.map(childTopic => (
    <Menu.Item
      href={getGroupDiscussionUrl(childTopic.contextId, childTopic._id)}
      key={childTopic._id}
      data-testid="groups-menu-item"
    >
      <Tooltip renderTip={childTopic.contextName} key={childTopic._id}>
        <PresentationContent>
          <Flex direction="row" gap="medium" justifyItems="space-between" alignItems="center">
            <TruncateText position="middle" maxLines="1">
              <Flex.Item data-testid="truncated-name">{childTopic.contextName}</Flex.Item>
            </TruncateText>
            <Flex.Item>
              <Text weight="light">
                {I18n.t('%{unreadCount} Unread', {
                  unreadCount: childTopic.entryCounts.unreadCount,
                })}
              </Text>
            </Flex.Item>
          </Flex>
        </PresentationContent>
        <ScreenReaderContent>
          {childTopic.contextName}
          {/* whitespace is needed to avoid reading names, that end with a number wrongly,
          like, "my_group 1" with 0 unread could be read as 10 unread without this */}
          &nbsp;
          {I18n.t('%{unreadCount} Unread', {
            unreadCount: childTopic.entryCounts.unreadCount,
          })}
        </ScreenReaderContent>
      </Tooltip>
    </Menu.Item>
  ))

  const groupDiscussionButton = (
    <span className="discussions-group-discussion-btn">
      <Button
        renderIcon={IconGroupLine}
        data-testid="groups-menu-btn"
        type="button"
        display="block"
        style={{width: '100%'}}
        disabled={!props.childTopics?.length}
      >
        <ScreenReaderContent>{I18n.t('Group discussions')}</ScreenReaderContent>
        {I18n.t('Group discussion')}
      </Button>
    </span>
  )

  return (
    <Menu
      placement="bottom"
      trigger={
        !props.childTopics?.length ? (
          <Tooltip renderTip={I18n.t('There are no groups in this group set')}>
            {groupDiscussionButton}
          </Tooltip>
        ) : (
          groupDiscussionButton
        )
      }
    >
      {menuItems}
    </Menu>
  )
}

GroupsMenu.propTypes = {
  /**
   * Link to discussions RSS feed
   */
  childTopics: PropTypes.arrayOf(ChildTopic.shape).isRequired,
}
