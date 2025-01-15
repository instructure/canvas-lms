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

import {IconMoreSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import React from 'react'
import {Menu} from '@instructure/ui-menu'
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'

const MoreMenuButton = props => {
  const clickOnMenuItem = clickItem => {
    clickItem()
  }

  return (
    <Menu
      placement="bottom start"
      trigger={
        <Button display="block" style={{width: '100%'}}>
          <IconMoreSolid />
        </Button>
      }
      withArrow={false}
    >
      {props.menuOptions.map(({text, clickItem, buttonIcon: ButtonIcon}) => {
        return (
          <Menu.Item key={text} onClick={() => clickOnMenuItem(clickItem)}>
            <Flex gap="small">
              {ButtonIcon && <ButtonIcon />}
              {text}
            </Flex>
          </Menu.Item>
        )
      })}
    </Menu>
  )
}

export default MoreMenuButton

export const MoreMenuButtonOptions = {
  text: PropTypes.string,
  clickItem: PropTypes.func,
  buttonIcon: PropTypes.elementType,
}

MoreMenuButton.propTypes = {
  menuOptions: PropTypes.arrayOf(PropTypes.shape(MoreMenuButtonOptions)).isRequired,
}
