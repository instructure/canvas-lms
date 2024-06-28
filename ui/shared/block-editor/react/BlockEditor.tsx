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
import {Editor, Frame} from '@craftjs/core'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Toolbox} from './components/editor/Toolbox'
import {Topbar} from './components/editor/Topbar'
import {blocks} from './components/blocks'
import {NewPageStepper} from './components/editor/NewPageStepper'
import {RenderNode} from './components/editor/RenderNode'
import {ErrorBoundary} from './components/editor/ErrorBoundary'

import './style.css'

const I18n = useI18nScope('block-editor')

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

type BlockEditorProps = {
  enabled?: boolean
  container: HTMLElement // the element that will shrink when drawers open
  version: string
  content: string
  onCancel: () => void
}

export default function BlockEditor({
  enabled = true,
  container,
  version,
  content,
  onCancel,
}: BlockEditorProps) {
  const [json] = useState(content || DEFAULT_CONTENT)
  const [toolboxOpen, setToolboxOpen] = useState(false)
  const [stepperOpen, setStepperOpen] = useState(!content)

  useEffect(() => {
    if (version !== '1') {
      // eslint-disable-next-line no-alert
      alert('wrong version, mayhem may ensue')
    }
  }, [json, version])

  const handleNodesChange = useCallback(query => {
    // @ts-expect-error
    window.block_editor = query
    // console.log(JSON.parse(query.serialize()))
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
          resolver={blocks}
          onNodesChange={handleNodesChange}
          onRender={RenderNode}
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
            <Flex.Item id="editor-area" shouldGrow={true}>
              <Frame data={json} />
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
