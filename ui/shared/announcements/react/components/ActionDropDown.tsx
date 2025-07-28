/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'

export interface ActionObject {
  label: string
  screenReaderLabel: string
  icon: React.ComponentType
  action: () => void
  disabled: boolean
}

type Props = {
  label: string
  actions: ActionObject[]
  disabled?: boolean
}

export const ActionDropDown: React.FC<Props> = ({label, actions, disabled = false}) => {
  const [dropdown_opened, setDropownOpened] = useState<boolean>(false)

  return (
    <View textAlign="center">
      <Menu
        disabled={disabled}
        placement="bottom stretch"
        themeOverride={{
          maxWidth: '100%',
        }}
        withArrow={false}
        trigger={
          <Button width="100%" display="block" data-testid="action-dropdown-button">
            <View margin="0 0 0 small">
              <PresentationContent>{label} </PresentationContent>
              <ScreenReaderContent>{label}</ScreenReaderContent>
              {dropdown_opened ? (
                <IconArrowOpenUpLine size="x-small" />
              ) : (
                <IconArrowOpenDownLine size="x-small" />
              )}
            </View>
          </Button>
        }
        onToggle={() => setDropownOpened(!dropdown_opened)}
      >
        {Object.values(actions).map(actionObject => {
          const IconComponent = actionObject.icon
          return (
            <Menu.Item
              onClick={actionObject.action}
              id={actionObject.label}
              key={actionObject.label}
              disabled={actionObject.disabled}
              data-testid={`action-dropdown-item-${actionObject.label}`}
            >
              <span>
                <IconComponent />
                <ScreenReaderContent>{actionObject.screenReaderLabel}</ScreenReaderContent>
                <PresentationContent> {actionObject.label}</PresentationContent>
              </span>
            </Menu.Item>
          )
        })}
      </Menu>
    </View>
  )
}
