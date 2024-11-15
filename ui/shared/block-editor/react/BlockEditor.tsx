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
import uuid from 'uuid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Toolbox} from './components/editor/Toolbox/Toolbox'
import {Topbar} from './components/editor/Topbar'
import {blocks} from './components/blocks'
import {RenderNode} from './components/editor/RenderNode'
import {ErrorBoundary} from './components/editor/ErrorBoundary'
import {closeExpandedBlocks} from './utils/cleanupBlocks'
import {
  transform,
  LATEST_BLOCK_DATA_VERSION,
  type BlockEditorDataTypes,
  type BlockEditorData,
  getTemplates,
} from './utils'
import {saveGlobalTemplateToFile} from './utils/saveGlobalTemplate'
import {
  type CanEditTemplates,
  type BlockTemplate,
  TemplateEditor,
  SaveTemplateEvent,
  DeleteTemplateEvent,
} from './types'

import './style.css'
import CreateFromTemplate from '@canvas/block-editor/react/CreateFromTemplate'

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

export type BlockEditorProps = {
  enabled?: boolean
  enableResizer?: boolean
  course_id: string
  container: HTMLElement // the element that will shrink when drawers open
  content: BlockEditorDataTypes
}

export default function BlockEditor({
  enabled = true,
  enableResizer = true,
  course_id,
  container,
  content,
}: BlockEditorProps) {
  const [data] = useState<BlockEditorData>(() => {
    return transform(content)
  })
  const [toolboxOpen, setToolboxOpen] = useState(false)
  const [templateEditor, setTemplateEditor] = useState<TemplateEditor>(TemplateEditor.UNKNOWN)
  const [blockTemplates, setBlockTemplates] = useState<BlockTemplate[]>([])
  const [blockEditorEditorEl, setBlockEditorEditorEl] = useState<HTMLDivElement | null>(null)

  RenderNode.globals.enableResizer = !!enableResizer

  // There are 2 sources of block templates, the database and global templates
  // currently imported from the assets folder (though this will eventually be replaced with an API call)
  const getBlockTemplates = useCallback(
    (editor: TemplateEditor) => {
      getTemplates({course_id, drafts: editor > 0, globals_only: false})
        .then(setBlockTemplates)
        .catch((err: Error) => {
          showFlashError(I18n.t('Cannot get block custom templates'))(err)
        })
    },
    [course_id]
  )

  const getTemplateEditor = useCallback(() => {
    doFetchApi<CanEditTemplates>({
      path: `/api/v1/courses/${course_id}/block_editor_templates/can_edit`,
      method: 'GET',
    })
      .then((response: DoFetchApiResults<CanEditTemplates>) => {
        let editor = response.json?.can_edit ? TemplateEditor.LOCAL : TemplateEditor.NONE
        if (editor && response.json?.can_edit_global) {
          editor = TemplateEditor.GLOBAL
        }
        setTemplateEditor(editor)
        RenderNode.globals.templateEditor = editor
        getBlockTemplates(editor)
      })
      .catch((err: Error) => {
        showFlashError(I18n.t('Failed getting template editor status.'))(err)
      })
  }, [course_id, getBlockTemplates])

  const saveGlobalTemplate = async (template: Partial<BlockTemplate>) => {
    try {
      await saveGlobalTemplateToFile(template)
    } catch (err: any) {
      showFlashError(I18n.t('Failed saving global template to a file'))(err)
    }
  }

  const saveBlockTemplate = useCallback(
    (template: Partial<BlockTemplate>) => {
      const path = template.id
        ? `/api/v1/courses/${course_id}/block_editor_templates/${template.id}`
        : `/api/v1/courses/${course_id}/block_editor_templates`
      const method = template.id ? 'PUT' : 'POST'
      doFetchApi<BlockTemplate>({
        path,
        method,
        body: JSON.stringify(template),
        headers: {'Content-Type': 'application/json'},
      })
        .then((response: DoFetchApiResults<BlockTemplate>) => {
          const newTemplate = response.json
          if (newTemplate) {
            const index = blockTemplates.findIndex(t => t.global_id === newTemplate.global_id)
            if (index >= 0) {
              const newTemplates = [...blockTemplates]
              newTemplates[index] = newTemplate
              setBlockTemplates(newTemplates)
            } else {
              setBlockTemplates([...blockTemplates, newTemplate])
            }
          }
        })
        .catch((err: Error) => {
          showFlashError(I18n.t('Failed saving template'))(err)
        })
    },
    [blockTemplates, course_id]
  )

  const deleteBlockTemplate = useCallback(
    (templateId: string) => {
      doFetchApi({
        path: `/api/v1/courses/${course_id}/block_editor_templates/${templateId}`,
        method: 'DELETE',
      })
        .then(() => {
          setBlockTemplates(blockTemplates.filter(t => t.id !== templateId))
        })
        .catch((err: Error) => {
          showFlashError(I18n.t('Failed deleting template'))(err)
        })
    },
    [blockTemplates, course_id]
  )

  const handleSaveTemplate = useCallback(
    (e: Event) => {
      const saveTemplateEvent = e as CustomEvent
      const template = saveTemplateEvent.detail.template
      const globalTemplate = saveTemplateEvent.detail.globalTemplate
      template.node_tree.nodes[template.node_tree.rootNodeId].custom.displayName = template.name
      template.editor_version = LATEST_BLOCK_DATA_VERSION

      if (globalTemplate) {
        template.global_id = template.id = uuid.v4()
        saveGlobalTemplate(template)
      } else {
        saveBlockTemplate(template)
      }
    },
    [saveBlockTemplate]
  )

  const handleDeleteTemplate = useCallback(
    (e: Event) => {
      const deleteTemplateEvent = e as CustomEvent
      const templateId = deleteTemplateEvent.detail
      deleteBlockTemplate(templateId)
    },
    [deleteBlockTemplate]
  )

  useEffect(() => {
    if (blockEditorEditorEl) {
      blockEditorEditorEl.addEventListener(SaveTemplateEvent, handleSaveTemplate)
      blockEditorEditorEl.addEventListener(DeleteTemplateEvent, handleDeleteTemplate)
    }

    return () => {
      if (blockEditorEditorEl) {
        blockEditorEditorEl.removeEventListener(SaveTemplateEvent, handleSaveTemplate)
        blockEditorEditorEl.removeEventListener(DeleteTemplateEvent, handleDeleteTemplate)
      }
    }
  }, [blockEditorEditorEl, handleSaveTemplate, handleDeleteTemplate])

  useEffect(() => {
    if (templateEditor === TemplateEditor.UNKNOWN) {
      getTemplateEditor()
    }
  }, [getTemplateEditor, templateEditor])

  useEffect(() => {
    if (data.version !== LATEST_BLOCK_DATA_VERSION) {
      // eslint-disable-next-line no-alert
      alert(I18n.t('Unknown block data version "%{v}", mayhem may ensue', {v: data.version}))
    }
  }, [data.version])

  const handleNodesChange = useCallback(
    (query: any) => {
      // @ts-expect-error
      window.block_editor = () => ({
        query,
        getBlocks: (): BlockEditorData => ({
          id: data.id || '',
          version: LATEST_BLOCK_DATA_VERSION,
          blocks: closeExpandedBlocks(query),
        }),
      })
    },
    [data.id]
  )

  const handleCloseToolbox = useCallback(() => {
    setToolboxOpen(false)
  }, [])

  const handleOpenToolbox = useCallback((open: boolean) => {
    setToolboxOpen(open)
  }, [])

  return (
    <View
      elementRef={(el: Element | null) => setBlockEditorEditorEl(el as HTMLDivElement)}
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

          <Toolbox
            open={toolboxOpen}
            templateEditor={templateEditor}
            container={container}
            onClose={handleCloseToolbox}
            templates={blockTemplates}
          />
          <CreateFromTemplate course_id={course_id} />
        </Editor>
      </ErrorBoundary>
    </View>
  )
}
