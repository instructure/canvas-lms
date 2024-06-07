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
  version: string
  content: string
}

export default function BlockEditor({enabled = true, version, content}: BlockEditorProps) {
  const [json] = useState(content || DEFAULT_CONTENT)
  const [toolboxOpen, setToolboxOpen] = useState(true)
  const [stepperOpen, setStepperOpen] = useState(!content)

  useEffect(() => {
    if (version !== '1') {
      // eslint-disable-next-line no-alert
      alert('wrong version, mayhem may ensue')
    }
  }, [json, version])

  const handleNodesChange = useCallback(query => {
    window.block_editor = query
    // const json = query.serialize()
    // console.log(JSON.parse(json))
  }, [])

  const handleCloseToolbox = useCallback(() => {
    setToolboxOpen(false)
  }, [])

  const handleOpenToolbox = useCallback(() => {
    setToolboxOpen(true)
  }, [])

  const handleCloseStepper = useCallback(() => {
    setStepperOpen(false)
  }, [])

  return (
    <View
      as="span"
      className="block-editor"
      display="inline-block"
      position="relative"
      width="100%"
      maxWidth="100%"
      margin="small"
      padding="small"
      shadow="above"
      borderRadius="large large none none"
    >
      <Editor
        enabled={enabled}
        resolver={blocks}
        onNodesChange={handleNodesChange}
        onRender={RenderNode}
      >
        <Flex direction="column" alignItems="stretch" justifyItems="start" gap="small" width="100%">
          <Flex.Item shouldGrow={false}>
            <Topbar onOpenToolbox={handleOpenToolbox} />
          </Flex.Item>
          <Flex.Item id="editor-area" shouldGrow={true}>
            <Frame data={json} />
          </Flex.Item>
        </Flex>

        <Toolbox open={toolboxOpen} onClose={handleCloseToolbox} />
        <NewPageStepper open={stepperOpen} onDismiss={handleCloseStepper} />
      </Editor>
    </View>
  )
}
