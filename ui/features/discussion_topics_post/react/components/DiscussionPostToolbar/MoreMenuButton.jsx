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
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useContext, useEffect, useState} from 'react'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussions_posts')

export const MoreMenuButton = () => {
  const [showMenu, setShowMenu] = useState(false)
  const {translationLanguages, setShowTranslationControl} = useContext(
    DiscussionManagerUtilityContext
  )
  const [translationOptionText, setTranslationOptionText] = useState(I18n.t('Translate Text'))
  const [hideTranslateText, setHideTranslateText] = useState(false)

  const toggleTranslateText = () => {
    // Update local state
    setHideTranslateText(!hideTranslateText)
    setTranslationOptionText(
      hideTranslateText ? I18n.t('Translate Text') : I18n.t('Hide Translate Text')
    )
    // Update context
    setShowTranslationControl(!hideTranslateText)
    setShowMenu(false)
  }

  const menuOptions = []
  if (translationLanguages.current.length > 0) {
    menuOptions.push({text: translationOptionText, onClick: toggleTranslateText})
  }

  return (
    <Menu
      placement="bottom start"
      trigger={
        <Button>
          <IconMoreSolid />
        </Button>
      }
      withArrow={false}
    >
      {menuOptions.map(({text, onClick}) => {
        return (
          <Menu.Item key={text} onClick={onClick}>
            {text}
          </Menu.Item>
        )
      })}
    </Menu>
  )
}
