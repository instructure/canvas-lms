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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {TopNavBar} from '@instructure/ui-top-nav-bar'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import classNames from 'classnames'

const I18n = useI18nScope('new_login')

interface Props {
  className?: string
}

const AppNavBar = ({className}: Props) => {
  const [state, setState] = useState({
    isSmallViewportMenuOpen: false,
  })

  const orgName = <Text>{I18n.t('Canvas')}</Text>

  return (
    <TopNavBar
      className={classNames(className)}
      breakpoint="650"
      inverseColor={true}
      mediaQueryMatch="element"
    >
      {() => {
        return (
          <TopNavBar.Layout
            navLabel="Example navigation bar"
            smallViewportConfig={{
              dropdownMenuToggleButtonLabel: 'Toggle Menu',
              dropdownMenuLabel: 'Main Menu',
              onDropdownMenuToggle: isMenuOpen => {
                setState({...state, isSmallViewportMenuOpen: isMenuOpen})
              },
              alternativeTitle: 'Overview',
            }}
            renderBrand={
              <TopNavBar.Brand
                screenReaderLabel="Name of organization"
                renderIcon={
                  <View as="div" margin="small">
                    {orgName}
                  </View>
                }
              />
            }
            renderMenuItems={
              <TopNavBar.MenuItems
                listLabel="Page navigation"
                renderHiddenItemsMenuTriggerLabel={hiddenChildrenCount =>
                  `${hiddenChildrenCount} More`
                }
              >
                <TopNavBar.Item id="link1" href="#">
                  Link
                </TopNavBar.Item>
                <TopNavBar.Item id="link2" href="#">
                  Link
                </TopNavBar.Item>
              </TopNavBar.MenuItems>
            }
          />
        )
      }}
    </TopNavBar>
  )
}

export default AppNavBar
