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
// components/Toolbox.js
import React, {useCallback, useEffect, useRef, useState} from 'react'

import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Tray} from '@instructure/ui-tray'

import {mountNode} from '../../../utils'
import {
  type BlockTemplate,
  DeleteTemplateEvent,
  SaveTemplateEvent,
  dispatchTemplateEvent,
  TemplateEditor,
} from '../../../types'
import {type ToolboxProps, type KeyboardOrMouseEvent} from './types'
import {type OnRequestTabChangeHandler} from '../types'
import {EditTemplateModal, type OnSaveTemplateCallback} from '../EditTemplateModal'
import {BlocksPanel} from './BlocksPanel'
import {SectionsPanel} from './SectionsPanel'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export const Toolbox = ({
  toolboxShortcutManager,
  open,
  container,
  templateEditor,
  templates,
  onDismiss,
  onOpened,
}: ToolboxProps) => {
  const [trayRef, setTrayRef] = useState<HTMLElement | null>(null)
  const [containerStyle] = useState<Partial<CSSStyleDeclaration>>(() => {
    if (container) {
      return {
        width: container.style.width,
        boxSizing: container.style.boxSizing,
        transition: container.style.transition,
      } as Partial<CSSStyleDeclaration>
    }
    return {}
  })
  const [editTemplate, setEditTemplate] = useState<BlockTemplate | null>(null)
  const [activeTab, setActiveTab] = useState('sections')
  const trayHeadingRef = useRef<HTMLElement | null>(null)
  const {defaultFocusRef, keyDownHandler} = toolboxShortcutManager

  useEffect(() => {
    if (trayRef) {
      trayRef.addEventListener('keydown', keyDownHandler)
    }

    return () => {
      if (trayRef) {
        trayRef.removeEventListener('keydown', keyDownHandler)
      }
    }
  }, [keyDownHandler, trayRef])

  useEffect(() => {
    const shrinking_selector = '.edit-content' // '.block-editor-editor'

    if (open && trayRef) {
      const ed = document.querySelector(shrinking_selector) as HTMLElement | null

      if (!ed) return
      const ed_rect = ed.getBoundingClientRect()
      const tray_left = window.innerWidth - trayRef.offsetWidth
      if (ed_rect.right > tray_left) {
        ed.style.width = `${ed_rect.width - (ed_rect.right - tray_left)}px`
      }
    } else {
      const ed = document.querySelector(shrinking_selector) as HTMLElement | null
      if (!ed) return
      ed.style.boxSizing = containerStyle.boxSizing || ''
      ed.style.width = containerStyle.width || ''
      ed.style.transition = containerStyle.transition || ''
    }
  }, [containerStyle, open, trayRef])

  const handleCloseTray = useCallback(() => {
    onDismiss()
  }, [onDismiss])

  const handleDeleteTemplate = useCallback((templateId: string) => {
    if (window.confirm(I18n.t('Are you sure you want to delete this template?'))) {
      const event = new CustomEvent(DeleteTemplateEvent, {
        detail: templateId,
      })
      dispatchTemplateEvent(event)
    }
  }, [])

  const handleEditTemplate = useCallback(
    (templateId: string) => {
      const template = templates.find(t => t.id === templateId)
      if (template) {
        setEditTemplate(template)
      }
    },
    [templates],
  )

  const handleSaveTemplate: OnSaveTemplateCallback = useCallback(
    ({name, description, workflow_state}, globalTemplate) => {
      const newTemplate = {...editTemplate, name, description, workflow_state}
      const event = new CustomEvent(SaveTemplateEvent, {
        detail: {template: newTemplate, globalTemplate},
      })
      dispatchTemplateEvent(event)
      setEditTemplate(null)
    },
    [editTemplate],
  )

  const handleTabChange: OnRequestTabChangeHandler = useCallback((_e, tabData) => {
    setActiveTab(tabData.id as string)
  }, [])

  const trayHeight = trayRef?.offsetHeight || window.innerHeight
  const trayHeadingHeight = trayHeadingRef.current?.offsetHeight || 48
  const tabsHeight = `${trayHeight - trayHeadingHeight}px`

  return (
    <>
      <Tray
        contentRef={el => setTrayRef(el)}
        label={I18n.t('Add content tray')}
        mountNode={mountNode()}
        open={open}
        placement="end"
        size="small"
        shouldContainFocus={false}
        onClose={handleCloseTray}
        onOpen={onOpened}
      >
        <Flex as="div" direction="column" padding="small" height="100vh">
          <Flex
            margin="0 0 small"
            gap="medium"
            elementRef={el => {
              if (el) trayHeadingRef.current = el as HTMLElement
            }}
          >
            <CloseButton
              placement="end"
              onClick={handleCloseTray}
              screenReaderLabel="Close"
              elementRef={el => {
                if (typeof defaultFocusRef === 'function') defaultFocusRef(el as HTMLElement)
                else if (defaultFocusRef)
                  (defaultFocusRef as React.MutableRefObject<HTMLElement | null>).current =
                    el as HTMLElement
              }}
            />
            <Heading level="h3">{I18n.t('Add Content')}</Heading>
          </Flex>
          <Flex.Item shouldShrink={true} overflowX="hidden">
            <Tabs onRequestTabChange={handleTabChange} height={tabsHeight}>
              <Tabs.Panel
                id="sections"
                renderTitle={I18n.t('Sections')}
                isSelected={activeTab === 'sections'}
              >
                <SectionsPanel
                  templateEditor={templateEditor}
                  templates={templates}
                  onEditTemplate={handleEditTemplate}
                  onDeleteTemplate={handleDeleteTemplate}
                />
              </Tabs.Panel>
              <Tabs.Panel
                id="blocks"
                renderTitle={I18n.t('Blocks')}
                isSelected={activeTab === 'blocks'}
              >
                <BlocksPanel
                  templateEditor={templateEditor}
                  templates={templates}
                  onEditTemplate={handleEditTemplate}
                  onDeleteTemplate={handleDeleteTemplate}
                />
              </Tabs.Panel>
            </Tabs>
          </Flex.Item>
        </Flex>
      </Tray>
      {editTemplate && (
        <EditTemplateModal
          mode="edit"
          template={editTemplate}
          templateType="block"
          isGlobalEditor={templateEditor === TemplateEditor.GLOBAL}
          onDismiss={() => setEditTemplate(null)}
          onSave={handleSaveTemplate}
        />
      )}
    </>
  )
}
