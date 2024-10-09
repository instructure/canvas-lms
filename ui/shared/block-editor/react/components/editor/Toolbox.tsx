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
import React, {useCallback, useEffect, useState} from 'react'
import {useEditor} from '@craftjs/core'

import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {SVGIcon} from '@instructure/ui-svg-images'
import {IconAdminToolsLine, IconEditLine, IconXLine} from '@instructure/ui-icons'

import {ButtonBlock, ButtonBlockIcon} from '../user/blocks/ButtonBlock'
import {TextBlock, TextBlockIcon} from '../user/blocks/TextBlock'
import {HeadingBlock, HeadingBlockIcon} from '../user/blocks/HeadingBlock'
import {ResourceCard, ResourceCardIcon} from '../user/blocks/ResourceCard'
import {ImageBlock, ImageBlockIcon} from '../user/blocks/ImageBlock'
import {IconBlock, IconBlockIcon} from '../user/blocks/IconBlock'
import {RCEBlock, RCEBlockIcon} from '../user/blocks/RCEBlock'
import {TabsBlock, TabsBlockIcon} from '../user/blocks/TabsBlock'
import {GroupBlock, GroupBlockIcon} from '../user/blocks/GroupBlock'
import {mountNode, createFromTemplate} from '../../utils'
import {
  type BlockTemplate,
  DeleteTemplateEvent,
  SaveTemplateEvent,
  dispatchTemplateEvent,
  TemplateEditor,
} from '../../types'
import {EditTemplateModal} from './EditTemplateModal'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

export type ToolboxProps = {
  open: boolean
  container: HTMLElement
  templateEditor: TemplateEditor
  templates: BlockTemplate[]
  onClose: () => void
}

export const Toolbox = ({open, container, templateEditor, templates, onClose}: ToolboxProps) => {
  const {connectors, query} = useEditor()
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
    onClose()
  }, [onClose])

  const handleDeleteTemplate = useCallback((templateId: string) => {
    // eslint-disable-next-line no-alert
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
    [templates]
  )

  const handleSaveTemplate = useCallback(
    ({name, description, workflow_state}: Partial<BlockTemplate>, globalTemplate: boolean) => {
      const newTemplate = {...editTemplate, name, description, workflow_state}
      const event = new CustomEvent(SaveTemplateEvent, {
        detail: {template: newTemplate, globalTemplate},
      })
      dispatchTemplateEvent(event)
      setEditTemplate(null)
    },
    [editTemplate]
  )

  const renderTemplateBox = (template: BlockTemplate) => {
    if (!template?.node_tree) return null
    const isDraft = template.workflow_state !== 'active'
    return (
      <View
        key={`template-${template.id}`}
        position="relative"
        shadow="resting"
        className="toolbox-item item-template-block"
        textAlign="center"
        elementRef={(ref: Element | null) => {
          if (!ref) return
          connectors.create(ref as HTMLElement, () => {
            return createFromTemplate(template.node_tree, query)
          })
        }}
        borderWidth="small"
        borderColor={isDraft ? 'warning' : 'transparent'}
      >
        {templateEditor ? (
          <div
            style={{
              position: 'absolute',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '4px',
              top: 0,
              right: 0,
              lineHeight: '.75rem',
            }}
          >
            <IconButton
              themeOverride={{smallHeight: '.75rem'}}
              screenReaderLabel={I18n.t('Edit Template')}
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={handleEditTemplate.bind(null, template.id)}
            >
              <IconEditLine size="x-small" themeOverride={{sizeXSmall: '.5rem'}} />
            </IconButton>
            <IconButton
              themeOverride={{smallHeight: '.75rem'}}
              screenReaderLabel={I18n.t('Delete Template')}
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={handleDeleteTemplate.bind(null, template.id)}
            >
              <IconXLine size="x-small" themeOverride={{sizeXSmall: '.5rem'}} />
            </IconButton>
          </div>
        ) : null}
        <Flex
          direction="column"
          justifyItems="center"
          alignItems="center"
          width="78px"
          height="78px"
        >
          <IconAdminToolsLine size="x-small" />
          <Text size="small">{template.name || 'Template'}</Text>
        </Flex>
      </View>
    )
  }

  const renderTemplateBoxes = () => {
    return templates
      .filter(t => t.template_type === 'block')
      .map(template => {
        return renderTemplateBox(template)
      })
  }

  const renderBox = (label: string, icon: string, element: JSX.Element) => {
    return (
      <View
        shadow="resting"
        className={`toolbox-item item-${label.toLowerCase().replaceAll(' ', '')}-block`}
        textAlign="center"
        elementRef={(ref: Element | null) => ref && connectors.create(ref as HTMLElement, element)}
      >
        <Flex
          direction="column"
          justifyItems="center"
          alignItems="center"
          width="78px"
          height="78px"
        >
          <SVGIcon src={icon} size="x-small" />
          <Text size="small">{label}</Text>
        </Flex>
      </View>
    )
  }

  return (
    <>
      <Tray
        contentRef={el => setTrayRef(el)}
        label="Toolbox"
        mountNode={mountNode()}
        open={open}
        placement="end"
        size="small"
        onClose={handleCloseTray}
      >
        <View as="div" margin="small">
          <Flex margin="0 0 small" gap="medium">
            <CloseButton placement="end" onClick={handleCloseTray} screenReaderLabel="Close" />
            <Heading level="h3">Blocks</Heading>
            {/* <CondensedButton renderIcon={IconOpenFolderLine}>Section Browser</CondensedButton> */}
          </Flex>
          <Flex
            gap="x-small"
            justifyItems="space-between"
            alignItems="center"
            wrap="wrap"
            padding="x-small"
          >
            {renderBox('Button', ButtonBlockIcon, <ButtonBlock text="Click me" />)}
            {renderBox('Text', TextBlockIcon, <TextBlock />)}
            {renderBox('RCE', RCEBlockIcon, <RCEBlock text="" />)}
            {renderBox('Icon', IconBlockIcon, <IconBlock iconName="apple" />)}
            {renderBox('Heading', HeadingBlockIcon, <HeadingBlock />)}
            {renderBox('Resource Card', ResourceCardIcon, <ResourceCard />)}
            {renderBox('Image', ImageBlockIcon, <ImageBlock />)}
            {renderBox('Group', GroupBlockIcon, <GroupBlock />)}
            {renderBox('Tabs', TabsBlockIcon, <TabsBlock />)}
            {renderTemplateBoxes()}
          </Flex>
        </View>
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
