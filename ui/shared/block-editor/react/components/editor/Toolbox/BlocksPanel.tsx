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
import {useEditor, type EditorState} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconAdminToolsLine} from '@instructure/ui-icons'

import {ButtonBlock, ButtonBlockIcon} from '../../user/blocks/ButtonBlock'
import {ImageBlock, ImageBlockIcon} from '../../user/blocks/ImageBlock'
import {MediaBlock, MediaBlockIcon} from '../../user/blocks/MediaBlock'
import {IconBlock, IconBlockIcon} from '../../user/blocks/IconBlock'
import {RCETextBlock, RCETextBlockIcon} from '../../user/blocks/RCETextBlock'
import {TabsBlock, TabsBlockIcon} from '../../user/blocks/TabsBlock'
import {GroupBlock, GroupBlockIcon} from '../../user/blocks/GroupBlock'
import {DividerBlock, DividerBlockIcon} from '../../user/blocks/DividerBlock'

import {createFromTemplate} from '../../../utils'
import {type BlockTemplate, type TemplateNodeTree} from '../../../types'
import {type TemplatePanelProps} from './types'
import {EditTemplateButtons} from './EditTemplateButtons'

type BlocksPanelProps = TemplatePanelProps & {
  onDeleteTemplate: (id: string) => void
  onEditTemplate: (id: string) => void
}

const BlocksPanel = ({
  templateEditor,
  templates,
  onDeleteTemplate,
  onEditTemplate,
}: BlocksPanelProps) => {
  const {actions, connectors, selected, query} = useEditor((state: EditorState) => {
    return {
      selected: state.events.selected,
    }
  })
  const [lastTargetParent, setLastTargetParent] = useState<string | undefined>(undefined)

  // Given a node, find the last canvas node that is a linked node
  // This should be the NoSections inner element of a GroupBlock
  const getFirstCandidateChild = useCallback(
    (parentId: string = 'ROOT'): string | undefined => {
      const parent = query.node(parentId)
      if (parent.isCanvas() && parent.isLinkedNode()) {
        return parentId
      }
      const candidateId = query
        .node(parentId)
        .descendants(true)
        .findLast(nid => {
          const n = query.node(nid)
          return n.isCanvas() && n.isLinkedNode()
        })
      return candidateId
    },
    [query],
  )

  // if a node is selected, find where w/in that node to add the new block
  // if not, find the last target of the ROOT PageBlock
  const getBlockTargetParent = useCallback((): string | undefined => {
    let targetId = selected.values().next().value
    targetId = getFirstCandidateChild(targetId)
    if (targetId) {
      setLastTargetParent(targetId)
    } else {
      targetId = lastTargetParent
    }
    return targetId
  }, [getFirstCandidateChild, lastTargetParent, selected])

  const handleAddBlock = useCallback(
    (element: JSX.Element, event: React.KeyboardEvent | React.MouseEvent) => {
      event.preventDefault()
      const parentId = getBlockTargetParent()
      if (!parentId) {
         
        window.alert("I don't know where to put this block")
        return
      }
      const node_tree = query.parseReactElement(element).toNodeTree()
      actions.addNodeTree(node_tree, parentId)
    },
    [actions, getBlockTargetParent, query],
  )

  const handleAddBlockKey = useCallback(
    (element: JSX.Element, e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        handleAddBlock(element, e)
      }
    },
    [handleAddBlock],
  )

  const handleAddBlockTemplate = useCallback(
    (id: string) => {
      let node_tree
      const template = templates.find(t => t.id === id)
      if (template && template.node_tree) {
        node_tree = createFromTemplate(template.node_tree, query)
      }
      if (node_tree) {
        const parentId = getBlockTargetParent()
        actions.addNodeTree(node_tree, parentId)
      }
    },
    [actions, getBlockTargetParent, query, templates],
  )

  const handleAddBlockTemplateKey = useCallback(
    (id: string, e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        handleAddBlockTemplate(id)
      }
    },
    [handleAddBlockTemplate],
  )

  const renderBox = (label: string, icon: string, element: JSX.Element) => {
    return (
      <View
        as="div"
        position="relative"
        className={`toolbox-item item-block item-${label.toLowerCase().replaceAll(' ', '')}-block`}
        borderWidth="small"
        borderRadius="medium"
        borderColor="primary"
        elementRef={(ref: Element | null) => ref && connectors.create(ref as HTMLElement, element)}
        tabIndex={0}
        role="button"
        onClick={handleAddBlock.bind(null, element)}
        onKeyDown={handleAddBlockKey.bind(null, element)}
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

  const renderTemplateBox = (template: BlockTemplate) => {
    if (!template?.node_tree) return null
    const isDraft = template.workflow_state !== 'active'
    return (
      <View
        key={`template-${template.id}`}
        as="div"
        position="relative"
        borderWidth="small"
        borderRadius="medium"
        borderColor={isDraft ? 'warning' : 'primary'}
        className="toolbox-item item-template-block"
        textAlign="center"
        elementRef={(ref: Element | null) => {
          if (!ref) return
          connectors.create(ref as HTMLElement, () => {
            return createFromTemplate(template.node_tree as TemplateNodeTree, query)
          })
        }}
        tabIndex={0}
        role="button"
        onClick={handleAddBlockTemplate.bind(null, template.id)}
        onKeyDown={handleAddBlockTemplateKey.bind(null, template.id)}
        data-testid="blocks-panel-view-item-template-block"
      >
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
        {templateEditor ? (
          <EditTemplateButtons
            templateId={template.id}
            onEditTemplate={onEditTemplate}
            onDeleteTemplate={onDeleteTemplate}
          />
        ) : null}
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

  return (
    <Flex gap="x-small" justifyItems="space-between" alignItems="center" wrap="wrap">
      {renderBox('Button', ButtonBlockIcon, <ButtonBlock text="Click me" />)}
      {renderBox('Text', RCETextBlockIcon, <RCETextBlock text="" />)}
      {renderBox('Icon', IconBlockIcon, <IconBlock iconName="apple" />)}
      {renderBox('Image', ImageBlockIcon, <ImageBlock />)}
      {renderBox('Media', MediaBlockIcon, <MediaBlock />)}
      {renderBox('Group', GroupBlockIcon, <GroupBlock />)}
      {renderBox('Tabs', TabsBlockIcon, <TabsBlock />)}
      {renderBox('Divider', DividerBlockIcon, <DividerBlock />)}
      {renderTemplateBoxes()}
    </Flex>
  )
}

export {BlocksPanel, type BlocksPanelProps}
