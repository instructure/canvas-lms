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
import {ChildTopic} from '../../../graphql/ChildTopic'
import {getGroupDiscussionUrl} from '../../utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconGroupLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import PropTypes from 'prop-types'
import React, {useMemo} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('discussion_posts')

export const GroupsMenu = ({...props}) => {
  const menuItems = useMemo(
    () =>
      props.childTopics?.map(childTopic => (
        <Menu.Item
          href={getGroupDiscussionUrl(childTopic.contextId, childTopic._id)}
          key={childTopic._id}
        >
          {childTopic.contextName}
        </Menu.Item>
      )),
    [props.childTopics]
  )

  return (
    <Menu
      placement="bottom"
      trigger={
        <Button renderIcon={IconGroupLine} data-testid="groups-menu-btn" type="button">
          <ScreenReaderContent>{I18n.t('Group discussions')}</ScreenReaderContent>
        </Button>
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
  childTopics: PropTypes.arrayOf(ChildTopic.shape).isRequired
}
