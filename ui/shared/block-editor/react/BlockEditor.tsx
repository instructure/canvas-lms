/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {type NodeId, DefaultEventHandlers, Editor, Frame} from '@craftjs/core'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Toolbox} from './components/editor/Toolbox'
import {Topbar} from './components/editor/Topbar'
import {blocks} from './components/blocks'
import {NewPageStepper} from './components/editor/NewPageStepper'
import {RenderNode} from './components/editor/RenderNode'
import {ErrorBoundary} from './components/editor/ErrorBoundary'
import {closeExpandedBlocks} from './utils/cleanupBlocks'
import {
  transform,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorDataTypes,
  type BlockEditorData,
} from './utils/transformations'

import './style.css'

const I18n = useI18nScope('block-editor')

class CustomEventHandlers extends DefaultEventHandlers {
  loaded: boolean = false

  handleDrop = (el: HTMLElement, id: NodeId) => {
    // on initial load, the root node is the last selected
    // wait for that before handling drops
    if (id === 'ROOT') {
      this.loaded = true
      return
    }
    if (this.loaded) {
      this.options.store.actions.selectNode(id)
      el.focus()
    }
  }

  handlers() {
    const defaultHandlers = super.handlers()
    return {
      ...defaultHandlers,
      drop: (el: HTMLElement, id: NodeId) => {
        this.handleDrop(el, id)
        return defaultHandlers.drop(el, id)
      },
    }
  }
}

const DEFAULT_CONTENT = JSON.stringify({
  ROOT: {
    type: {
      resolvedName: 'PageBlock',
    },
    isCanvas: true,
    props: {},
    displayName: 'Page',
    custom: {},
    hidden: false,
    nodes: [],
    linkedNodes: {},
  },
})

export type BlockEditorProps = {
  enabled?: boolean
  enableResizer?: boolean
  container: HTMLElement // the element that will shrink when drawers open
  content: BlockEditorDataTypes
  onCancel: () => void
}

export default function BlockEditor({
  enabled = true,
  enableResizer = true,
  container,
  content,
  onCancel,
}: BlockEditorProps) {
  const [data] = useState<BlockEditorData>(() => {
    if (content?.blocks) {
      return transform(content)
    }
    return {version: '0.2', blocks: DEFAULT_CONTENT} as BlockEditorData
  })
  const [toolboxOpen, setToolboxOpen] = useState(false)
  const [stepperOpen, setStepperOpen] = useState(!content?.blocks)

  RenderNode.globals.enableResizer = !!enableResizer

  useEffect(() => {
    if (data.version !== LATEST_BLOCK_DATA_VERSION) {
      // eslint-disable-next-line no-alert
      alert(I18n.t('Unknown block data version "%{v}", mayhem may ensue', {v: data.version}))
    }
  }, [data.version])

  const handleNodesChange = useCallback((query: any) => {
    // @ts-expect-error
    window.block_editor = () => ({
      query,
      getBlocks: (): BlockEditorData => ({
        version: '0.2',
        blocks: closeExpandedBlocks(query),
      }),
    })
  }, [])

  const handleCloseToolbox = useCallback(() => {
    setToolboxOpen(false)
  }, [])

  const handleOpenToolbox = useCallback((open: boolean) => {
    setToolboxOpen(open)
  }, [])

  const handleCloseStepper = useCallback(() => {
    setStepperOpen(false)
    setToolboxOpen(true)
  }, [])

  const handleCancelStepper = useCallback(() => {
    setStepperOpen(false)
    onCancel()
  }, [onCancel])

  return (
    <View
      as="div"
      className="block-editor-editor"
      display="inline-block"
      position="relative"
      width="100%"
      maxWidth="100%"
      padding="small"
      shadow="above"
      borderRadius="large large none none"
    >
      <ErrorBoundary>
        <Editor
          enabled={enabled}
          indicator={{
            className: 'block-editor-dnd-indicator',
            error: 'red',
            success: 'rgb(98, 196, 98)',
          }}
          resolver={blocks}
          onNodesChange={handleNodesChange}
          onRender={RenderNode}
          handlers={store =>
            new CustomEventHandlers({
              store,
              isMultiSelectEnabled: () => false,
              removeHoverOnMouseleave: true,
            })
          }
        >
          <Flex
            direction="column"
            alignItems="stretch"
            justifyItems="start"
            gap="small"
            width="100%"
          >
            <div style={{position: 'sticky', top: 0, zIndex: 9999}}>
              <Topbar onToolboxChange={handleOpenToolbox} toolboxOpen={toolboxOpen} />
            </div>
            <Flex.Item id="editor-area" shouldGrow={true} role="tree">
              <Frame data={data.blocks} />
            </Flex.Item>
          </Flex>

          <Toolbox open={toolboxOpen} container={container} onClose={handleCloseToolbox} />
          <NewPageStepper
            open={stepperOpen}
            onFinish={handleCloseStepper}
            onCancel={handleCancelStepper}
          />
        </Editor>
      </ErrorBoundary>
    </View>
  )
}
