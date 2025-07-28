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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {
  IconArrowOpenStartLine,
  IconArrowOpenEndLine,
  IconTrashLine,
  IconSaveLine,
} from '@instructure/ui-icons'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Flex} from '@instructure/ui-flex'
import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {type ViewProps} from '@instructure/ui-view'
import {findFocusable} from '@instructure/ui-dom-utils'
import {
  captureElementThumbnail,
  isLastChild,
  mountNode,
  findUpNode,
  findDownNode,
  getToolbarPos,
  getArrowNext,
  getArrowPrev,
  getNodeTemplate,
  saveTemplateImages,
  type ImagesMapping,
} from '../../utils'
import {EditTemplateModal} from './EditTemplateModal'
import {
  type BlockTemplate,
  type TemplateType,
  SaveTemplateEvent,
  dispatchTemplateEvent,
  TemplateEditor,
} from '../../types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const moveIcon = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M8.77359 0L5.00002 3.77358L5.77532 4.54998L8.22638 2.09893V15.901L5.77532 13.451L5.00002 14.2263L8.77359 17.9999L12.5472 14.2263L11.773 13.451L9.3219 15.901V2.09893L11.773 4.54998L12.5472 3.77358L8.77359 0Z" fill="#273540"/>
<path fill-rule="evenodd" clip-rule="evenodd" d="M18 8.77358L14.2264 5L13.45 5.77531L15.9011 8.22637L2.09904 8.22637L4.549 5.77531L3.77369 5L0.000108554 8.77358L3.77369 12.5472L4.549 11.7729L2.09904 9.32189L15.9011 9.32189L13.45 11.7729L14.2264 12.5472L18 8.77358Z" fill="#273540"/>
</svg>
`

const Arrows = ['ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft']

function isBlockSaveable(templateEditor: TemplateEditor, node: Node) {
  if (templateEditor <= 0) return false
  if (
    templateEditor === TemplateEditor.LOCAL &&
    node.data.name !== 'PageBlock' &&
    (node.data.custom?.isSection || node.data.name === 'GroupBlock')
  ) {
    return true
  }
  if (
    templateEditor === TemplateEditor.GLOBAL &&
    (node.data.name === 'PageBlock' ||
      node.data.custom?.isSection ||
      node.data.name === 'GroupBlock')
  ) {
    return true
  }
  return false
}

type BlockToolbarProps = {
  templateEditor: TemplateEditor
}

const BlockToolbar = ({templateEditor}: BlockToolbarProps) => {
  const {actions, query} = useEditor()
  const {
    node,
    name,
    moveable,
    deletable,
    saveable,
    connectors: {drag},
  } = useNode((n: Node) => {
    const node_helpers = query.node(n.id)
    return {
      node: n,
      name: n.data.custom.displayName || n.data.displayName,
      moveable: node_helpers.isDraggable(),
      deletable: n.data.custom?.isSection
        ? !isLastChild(n.id, query)
        : (typeof n.data.custom?.isDeletable === 'function'
            ? n.data.custom.isDeletable?.(n.id, query)
            : true) && node_helpers.isDeletable(),
      saveable: isBlockSaveable(templateEditor, n),
    }
  })
  const [arrowNext] = useState<string[]>(getArrowNext())
  const [arrowPrev] = useState<string[]>(getArrowPrev())
  const [mountPoint] = useState(mountNode())
  const [currentToolbarRef, setCurrentToolbarRef] = useState<HTMLDivElement | null>(null)
  const [upnodeId] = useState<string | undefined>(findUpNode(node, query, templateEditor)?.id)
  const [downnodeId] = useState<string | undefined>(findDownNode(node, query)?.id)
  const [focusable, setFocusable] = useState<HTMLElement[]>([])
  const [currFocusedIndex, setCurrFocusedIndex] = useState<number>(0)
  const [showEditTemplateModal, setShowEditTemplateModal] = useState(false)
  const [templateType, setTemplateType] = useState<TemplateType>('block')

  useEffect(() => {
    setFocusable(findFocusable(currentToolbarRef) as HTMLElement[])
  }, [currentToolbarRef])

  useEffect(() => {
    focusable.forEach((el, index) => {
      el.setAttribute('tabindex', index === currFocusedIndex ? '0' : '-1')
    })
  }, [currFocusedIndex, currentToolbarRef, focusable])

  const handleFocus = useCallback(
    (e: React.FocusEvent) => {
      if (e.target === currentToolbarRef) {
        focusable[currFocusedIndex]?.focus()
      } else {
        const fidx = focusable.indexOf(e.target as HTMLElement)
        if (fidx !== -1) {
          setCurrFocusedIndex(fidx)
        }
      }
    },
    [currFocusedIndex, currentToolbarRef, focusable],
  )

  const handleKey = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      if (e.key === 'Escape' || arrowNext.includes(e.key) || arrowPrev.includes(e.key)) {
        e.preventDefault()
        e.stopPropagation()
      }

      if (e.key === 'Escape') {
        if (currentToolbarRef?.contains(document.activeElement)) {
          node.dom?.focus()
          return
        }
      }

      if (Arrows.includes(e.key)) {
        let focusedIndex = currFocusedIndex
        if (arrowNext.includes(e.key)) {
          focusedIndex = ++focusedIndex % focusable.length
        } else if (arrowPrev.includes(e.key)) {
          focusedIndex = (--focusedIndex + focusable.length) % focusable.length
        }
        setCurrFocusedIndex(focusedIndex)
        focusable[focusedIndex]?.focus()
      }
    },
    [arrowNext, arrowPrev, currFocusedIndex, currentToolbarRef, focusable, node.dom],
  )

  const handleGoUp = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.selectNode(upnodeId)
      if (upnodeId) {
        query.node(upnodeId).get()?.dom?.focus()
      }
    },
    [actions, query, upnodeId],
  )

  const handleGoDown = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      actions.selectNode(downnodeId)
      if (downnodeId) {
        query.node(downnodeId).get()?.dom?.focus()
      }
    },
    [actions, query, downnodeId],
  )

  const handleDeleteNode = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      // when we delete a block, select its parent.
      // TODO: we should select the previous sibling or parent if no prev. sib.
      // but I have to refactor the functions in KBNavigator before doing that
      const parentId = query.node(node.id).get().data.parent
      actions.delete(node.id)
      requestAnimationFrame(() => {
        actions.selectNode(parentId || 'ROOT')
      })
    },
    [actions, node.id, query],
  )

  const handleSave = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      let type: TemplateType = 'block'
      if (node.data.name === 'PageBlock') {
        type = 'page'
      } else if (node.data.custom?.isSection) {
        type = 'section'
      }
      setTemplateType(type)
      setShowEditTemplateModal(true)
    },
    [node.data.custom.isSection, node.data.name],
  )

  const handleSaveTemplate = useCallback(
    async (template: Partial<BlockTemplate>, globalTemplate: boolean) => {
      setShowEditTemplateModal(false)

      template.node_tree = getNodeTemplate(node.id, template.name as string, query)
      template.template_type = templateType
      if (globalTemplate) {
        template.template_category = 'global'
      }

      let thumbnail: string | undefined
      if (['page', 'section'].includes(templateType) && node.dom) {
        thumbnail = await captureElementThumbnail(node.dom, templateType)
      }
      template.thumbnail = thumbnail

      if (globalTemplate) {
        // for now, we have to extract images from the template and save as files
        const imgmap: ImagesMapping = await saveTemplateImages(
          query.node(node.id)?.get().dom as HTMLElement,
        )

        // update ImageBlocks to point to the saved images
        Object.values(template.node_tree.nodes).forEach(n => {
          const n2 = n
          // @ts-expect-error rsolvedName DOES exist on n2.type. see node_modules/@craftjs/core/lib/interfaces/nodes.d.ts:55
          if (n2.type.resolvedName === 'ImageBlock') {
            const src: string = n2.props.src
            if (src && imgmap[src]) {
              n2.props.src = imgmap[src]
            }
          }
        })
      }

      const saveTemplateEvent = new CustomEvent(SaveTemplateEvent, {
        detail: {
          template,
          globalTemplate: globalTemplate && ['page', 'section'].includes(templateType),
        },
      })
      dispatchTemplateEvent(saveTemplateEvent)
    },
    [node.dom, node.id, query, templateType],
  )

  if (node.data?.custom?.noToolbar) return null
  if (!mountPoint) return null

  const {top, left} = getToolbarPos(node.dom, mountPoint, currentToolbarRef, true)

  // TODO: this should be role="toolbar" and nav with arrow keys
  return (
    <div
      ref={(el: HTMLDivElement) => setCurrentToolbarRef(el)}
      className="block-toolbar"
      role="toolbar"
      style={{
        left: `${left}px`,
        top: `${top}px`,
      }}
      tabIndex={-1}
      onFocus={handleFocus}
      onKeyDown={focusable.length > 0 ? handleKey : undefined}
    >
      <Flex as="div" padding="0 xx-small" gap="x-small">
        {upnodeId && (
          <IconButton
            cursor="pointer"
            size="small"
            onClick={handleGoUp}
            screenReaderLabel={I18n.t('Go up')}
            title={I18n.t('Go up')}
            withBackground={false}
            withBorder={false}
            data-testid="block-toolbar-icon-button-go-up"
          >
            <IconArrowOpenStartLine />
          </IconButton>
        )}

        <Text>{name}</Text>

        {downnodeId && (
          <IconButton
            cursor="pointer"
            size="small"
            onClick={handleGoDown}
            screenReaderLabel={I18n.t('Go down')}
            title={I18n.t('Go down')}
            withBackground={false}
            withBorder={false}
            data-testid="block-toolbar-icon-button-go-down"
          >
            <IconArrowOpenEndLine />
          </IconButton>
        )}

        {node.related.toolbar && (
          <>
            <div className="toolbar-separator" />
            {React.createElement(node.related.toolbar)}
          </>
        )}
        {moveable ? (
          <>
            <div className="toolbar-separator" />
            <IconButton
              cursor="move"
              size="small"
              elementRef={el => el && drag(el as HTMLElement)}
              screenReaderLabel={I18n.t('Drag to move')}
              title={I18n.t('Drag to move')}
              withBackground={false}
              withBorder={false}
            >
              <SVGIcon src={moveIcon} />
            </IconButton>
          </>
        ) : null}

        {deletable ? (
          <>
            <div className="toolbar-separator" />
            <IconButton
              cursor="pointer"
              size="small"
              onClick={handleDeleteNode}
              screenReaderLabel={I18n.t('Delete')}
              title={I18n.t('Delete')}
              withBackground={false}
              withBorder={false}
              color="danger"
              data-testid="block-toolbar-icon-button-delete"
            >
              <IconTrashLine />
            </IconButton>
          </>
        ) : null}
        {saveable ? (
          <>
            <div className="toolbar-separator" />
            <CondensedButton
              size="small"
              onClick={handleSave}
              renderIcon={<IconSaveLine />}
              color="secondary"
              themeOverride={{secondaryGhostColor: '#0e68b3'}}
              data-testid="block-toolbar-icon-button-save-template"
            >
              {I18n.t('Save as template')}
            </CondensedButton>
          </>
        ) : null}
        {showEditTemplateModal ? (
          <EditTemplateModal
            mode="save"
            templateType={templateType}
            isGlobalEditor={templateEditor === TemplateEditor.GLOBAL}
            onDismiss={() => setShowEditTemplateModal(false)}
            onSave={handleSaveTemplate}
          />
        ) : null}
      </Flex>
    </div>
  )
}

export {BlockToolbar, isBlockSaveable}
