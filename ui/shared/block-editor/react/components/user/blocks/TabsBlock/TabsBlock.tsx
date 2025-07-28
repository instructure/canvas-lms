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
import {Element, useNode, useEditor, type Node} from '@craftjs/core'
import ContentEditable from 'react-contenteditable'

import {InstUISettingsProvider} from '@instructure/emotion'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {Tabs} from '@instructure/ui-tabs'
import {type ViewOwnProps} from '@instructure/ui-view'
import {IconXLine} from '@instructure/ui-icons'
import {uid} from '@instructure/uid'

import {Container} from '../Container'
import {GroupBlock} from '../GroupBlock'
import {useClassNames, getContrastingColor, getEffectiveBackgroundColor} from '../../../../utils'
import type {TabsBlockTab, TabsBlockProps} from './types'
import {TabsBlockToolbar} from './TabsBlockToolbar'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const TabsBlock = ({tabs, variant}: TabsBlockProps) => {
  const {actions, enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    actions: {setProp},
    node,
    selected,
  } = useNode((n: Node) => ({
    node: n,
    selected: n.events.selected,
  }))
  const [activeTabIndex, setActiveTabIndex] = useState<number>(0)
  const [editable, setEditable] = useState(false)
  const [blockid] = useState(() => uid('tabs-block-', 2))
  const clazz = useClassNames(enabled, {empty: !tabs?.length, selected}, ['block', 'tabs-block'])
  const [containerRef, setContainerRef] = useState<HTMLElement | null>(null)

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
      tabData: {index: number},
    ) => {
      if (tabData.index === activeTabIndex) return
      setActiveTabIndex(tabData.index)
      // on switching tabs, craft will select the GroupBlock in the Tabs.Panel
      // we want to keep the TabsBlock selected
      window.setTimeout(() => {
        actions.selectNode(node.id)
        if (node.dom) {
          const theTab = node.dom.querySelector('[role="tab"][aria-selected="true"]') as HTMLElement
          theTab?.focus()
        }
      }, 10)
    },
    [actions, activeTabIndex, node.dom, node.id],
  )

  const handleTabTitleChange = useCallback(
    // @ts-expect-error
    e => {
      setProp((props: TabsBlockProps) => {
        if (!props.tabs) return
        props.tabs[activeTabIndex].title = e.target.value
      })
    },
    [activeTabIndex, setProp],
  )

  const handleTabTitleKey = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        e.stopPropagation()
      } else if (e.key === 'Escape') {
        e.preventDefault()
        e.stopPropagation()
        setEditable(false)
        // @ts-expect-error
        document.getElementById(`tab-${tabs[activeTabIndex].id}`)?.focus()
      } else if (['ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
        e.stopPropagation()
      }
    },
    [activeTabIndex, tabs],
  )

  const handleTabTitleFocus = useCallback(
    (tabIndex: number) => {
      setActiveTabIndex(tabIndex)
      actions.selectNode(node.id)
    },
    [actions, node.id],
  )

  const handleDeleteTab = useCallback(
    (tabIndex: number) => {
      if (!tabs) return
      const newTabs = [...tabs]
      newTabs.splice(tabIndex, 1)
      setProp((props: TabsBlockProps) => {
        props.tabs = newTabs
      })
    },
    [setProp, tabs],
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
    [blockid, editable, selected, tabs],
  )

  let color: string | undefined
  if (containerRef) {
    const gbcolor = getEffectiveBackgroundColor(containerRef)
    color = getContrastingColor(gbcolor)
  }

  const renderTabTitle = (title: string, index: number) => {
    return enabled && editable ? (
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
          <div style={{marginBlockStart: '-.5rem', color}}>
            <IconButton
              color="secondary"
              themeOverride={{smallHeight: '.75rem', secondaryGhostColor: color}}
              screenReaderLabel={I18n.t('Delete Tab')}
              title={I18n.t('Delete Tab')}
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
          <Element id={`${tab.id}_group`} is={GroupBlock} hidden={activeTabIndex !== index} />
        </Tabs.Panel>
      )
    })
  }

  return (
    <Container
      id={blockid}
      className={clazz}
      onKeyDown={handleKey}
      style={{color}}
      ref={setContainerRef}
    >
      <InstUISettingsProvider
        theme={{
          componentOverrides: {
            'Tabs.Tab': {
              defaultColor: color,
            },
            'Tabs.Panel': {
              background: 'transparent',
            },
            Tabs: {
              defaultBackground: 'transparent',
            },
          },
        }}
      >
        <Tabs
          variant={variant === 'classic' ? 'secondary' : 'default'}
          onRequestTabChange={handleTabChange}
        >
          {renderTabs()}
        </Tabs>
      </InstUISettingsProvider>
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
