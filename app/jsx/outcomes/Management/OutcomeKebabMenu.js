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
import {View} from '@instructure/ui-view'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {IconMoreLine, IconEditLine, IconTrashLine, IconMoveEndLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!OutcomeManagement'

const OutcomeKebabMenu = ({menuTitle, onMenuHandler}) => (
  <Menu
    trigger={
      <Button variant="icon" icon={IconMoreLine}>
        <ScreenReaderContent>{menuTitle || I18n.t('Menu')}</ScreenReaderContent>
      </Button>
    }
    onSelect={onMenuHandler}
  >
    <Menu.Item value="edit">
      <IconEditLine size="x-small" />
      <View padding="0 small">{I18n.t('Edit')}</View>
    </Menu.Item>
    <Menu.Item value="remove">
      <IconTrashLine size="x-small" />
      <View padding="0 small">{I18n.t('Remove')}</View>
    </Menu.Item>
    <Menu.Item value="move">
      <IconMoveEndLine size="x-small" />
      <View padding="0 small">{I18n.t('Move')}</View>
    </Menu.Item>
  </Menu>
)

OutcomeKebabMenu.propTypes = {
  onMenuHandler: PropTypes.func.isRequired,
  menuTitle: PropTypes.string
}

OutcomeKebabMenu.defaultProps = {
  menuTitle: ''
}

export default OutcomeKebabMenu
