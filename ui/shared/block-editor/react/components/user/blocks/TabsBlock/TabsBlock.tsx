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

import React, {useCallback, useEffect, useState} from 'react'
import {Element, useNode, useEditor} from '@craftjs/core'
import ContentEditable from 'react-contenteditable'

import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {Tabs} from '@instructure/ui-tabs'
import {type ViewOwnProps} from '@instructure/ui-view'
import {IconXLine} from '@instructure/ui-icons'
import {uid} from '@instructure/uid'

import {Container} from '../Container'
import {TabBlock} from './TabBlock'
import {useClassNames} from '../../../../utils'
import type {TabsBlockTab, TabsBlockProps} from './types'
import {TabsBlockToolbar} from './TabsBlockToolbar'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/tabs-block')

const TabsBlock = ({tabs, variant}: TabsBlockProps) => {
  const {actions, enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    actions: {setProp},
    id,
    selected,
  } = useNode(state => ({
    id: state.id,
    selected: state.events.selected,
  }))
  const [activeTabIndex, setActiveTabIndex] = useState<number>(0)
  const [editable, setEditable] = useState(false)
  const [blockid] = useState(() => uid('tabs-block-', 2))
  const clazz = useClassNames(enabled, {empty: !tabs?.length}, ['block', 'tabs-block'])

  useEffect(() => {
    if (!tabs || tabs.length === 0) {
      setProp((props: TabsBlockProps) => {
        props.tabs = TabsBlock.craft.defaultProps.tabs
      })
    }
  }, [tabs, setProp])

  const handleTabChange = useCallback(
    (
      _event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>,
      tabData: {index: number}
    ) => {
      setActiveTabIndex(tabData.index)
      actions.selectNode(id)
    },
    [actions, id]
  )

  const handleTabTitleChange = useCallback(
    e => {
      setProp((props: TabsBlockProps) => {
        if (!props.tabs) return
        props.tabs[activeTabIndex].title = e.target.value
      })
    },
    [activeTabIndex, setProp]
  )

  const handleTabTitleKey = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      e.stopPropagation()
    }
  }, [])

  const handleTabTitleFocus = useCallback(
    (tabIndex: number) => {
      setActiveTabIndex(tabIndex)
      actions.selectNode(id)
    },
    [actions, id]
  )

  const handleDeleteTab = useCallback(
    tabIndex => {
      if (!tabs) return
      const newTabs = [...tabs]
      newTabs.splice(tabIndex, 1)
      setProp((props: TabsBlockProps) => {
        props.tabs = newTabs
      })
    },
    [setProp, tabs]
  )

  const handleKey = useCallback(
    (e: React.KeyboardEvent) => {
      if (editable) {
        if (e.key === 'Escape') {
          e.preventDefault()
          e.stopPropagation()
          setEditable(false)
          document.getElementById(blockid)?.focus()
        }
      } else if (selected && tabs?.length && (e.key === 'Enter' || e.key === ' ')) {
        e.preventDefault()
        setEditable(true)
        const firstTab = document.getElementById(`tab-${tabs[0].id}`)
        if (firstTab) {
          const tabTitle = firstTab.querySelector('[contenteditable]') as HTMLElement
          tabTitle?.focus()
        }
      }
    },
    [blockid, editable, selected, tabs]
  )

  const renderTabTitle = (title: string, index: number) => {
    return enabled ? (
      <Flex gap="small">
        <ContentEditable
          data-placeholder={I18n.t('Tab Title')}
          html={title}
          tagName="span"
          onChange={handleTabTitleChange}
          onFocus={handleTabTitleFocus.bind(null, index)}
          onKeyDown={handleTabTitleKey}
        />
        {tabs && tabs.length > 1 && (
          <div style={{marginBlockStart: '-.5rem'}}>
            <IconButton
              themeOverride={{smallHeight: '.75rem'}}
              screenReaderLabel={I18n.t('Delete Tab')}
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={handleDeleteTab.bind(null, index)}
            >
              <IconXLine size="x-small" themeOverride={{sizeXSmall: '.5rem'}} />
            </IconButton>
          </div>
        )}
      </Flex>
    ) : (
      title
    )
  }

  const renderTabs = () => {
    return tabs?.map((tab: TabsBlockTab, index: number) => {
      return (
        <Tabs.Panel
          key={tab.id}
          id={tab.id}
          renderTitle={renderTabTitle(tab.title, index)}
          isSelected={activeTabIndex === index}
        >
          <Element
            id={`${tab.id}_nosection1`}
            tabId={tab.id}
            is={TabBlock}
            canvas={true}
            hidden={activeTabIndex !== index}
          />
        </Tabs.Panel>
      )
    })
  }

  return (
    <Container id={blockid} className={clazz} onKeyDown={handleKey}>
      <Tabs
        variant={variant === 'classic' ? 'secondary' : 'default'}
        onRequestTabChange={handleTabChange}
      >
        {renderTabs()}
      </Tabs>
    </Container>
  )
}

TabsBlock.craft = {
  displayName: I18n.t('Tabs'),
  defaultProps: {
    tabs: [
      {
        id: 'default-tab-1',
        title: 'Tab 1',
      },
      {
        id: 'default-tab-2',
        title: 'Tab 2',
      },
    ],
    variant: 'modern',
  },
  related: {
    toolbar: TabsBlockToolbar,
  },
  custom: {
    notTabContent: true,
    isBlock: true,
  },
}

export {TabsBlock}
