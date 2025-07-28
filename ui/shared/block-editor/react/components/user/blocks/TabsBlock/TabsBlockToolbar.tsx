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

import React, {useCallback, useState} from 'react'
import {useNode} from '@craftjs/core'
import {IconButton} from '@instructure/ui-buttons'
import {IconAddLine, IconFolderLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {uid} from '@instructure/uid'
import {type TabsBlockProps, type TabsBlockTab} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const TabsBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [tabs, setTabs] = useState<TabsBlockTab[]>(props.tabs || [])

  const handleAddTab = useCallback(() => {
    const newTab: TabsBlockTab = {
      id: uid('tab', 2),
      title: 'New Tab',
    }
    const newTabs = [...tabs, newTab]
    setTabs(newTabs)
    setProp((prps: TabsBlockProps) => {
      prps.tabs = newTabs
    })
  }, [setProp, tabs])

  const handleSelectVariant = useCallback(
    // @ts-expect-error
    (e, value) => {
      setProp((prps: TabsBlockProps) => {
        prps.variant = value
      })
    },
    [setProp],
  )

  return (
    <>
      <Menu
        trigger={
          <IconButton
            screenReaderLabel={I18n.t('Style')}
            title={I18n.t('Style')}
            size="small"
            withBackground={false}
            withBorder={false}
          >
            <IconFolderLine />
          </IconButton>
        }
      >
        <Menu.Item
          type="checkbox"
          value="modern"
          onSelect={handleSelectVariant}
          selected={props.variant === 'modern'}
        >
          {I18n.t('Modern')}
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="classic"
          onSelect={handleSelectVariant}
          selected={props.variant === 'classic'}
        >
          {I18n.t('Classic')}
        </Menu.Item>
      </Menu>

      <IconButton
        screenReaderLabel={I18n.t('Add Tab')}
        title={I18n.t('Add Tab')}
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={handleAddTab}
      >
        <IconAddLine />
      </IconButton>
    </>
  )
}

export {TabsBlockToolbar}
