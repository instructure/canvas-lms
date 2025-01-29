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

import React, {useCallback} from 'react'
import {useEditor} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {type TemplatePanelProps, type KeyboardOrMouseEvent} from './types'
import {TemplateEditor, type BlockTemplate, type TemplateNodeTree} from '../../../types'
import {createFromTemplate} from '../../../utils'
import {EditTemplateButtons} from './EditTemplateButtons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

interface SectionsPanelProps extends TemplatePanelProps {
  onDeleteTemplate: (id: string) => void
  onEditTemplate: (id: string) => void
}

const SectionsPanel = ({
  templateEditor,
  templates,
  onDeleteTemplate,
  onEditTemplate,
}: SectionsPanelProps) => {
  const {actions, connectors, query} = useEditor()

  const handleAddSection = useCallback(
    (id: string) => {
      let node_tree
      const template = templates.find(t => t.id === id)
      if (template && template.node_tree) {
        node_tree = createFromTemplate(template.node_tree, query)
      }
      if (node_tree) {
        actions.addNodeTree(node_tree, 'ROOT')
      }
    },
    [actions, query, templates],
  )

  const handleAddSectionKey = useCallback(
    (id: string, e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        handleAddSection(id)
      }
    },
    [handleAddSection],
  )

  const renderSection = (section_template: BlockTemplate) => {
    const isDraft = section_template.workflow_state !== 'active'
    return (
      <View
        id={`section_template-${section_template.id}`}
        key={section_template.id}
        as="div"
        borderWidth="small"
        borderRadius="medium"
        borderColor={isDraft ? 'warning' : 'primary'}
        margin="xx-small" /* necessary to see the shadow */
        padding="x-small"
        data-testid="preview-section"
        elementRef={(ref: Element | null) => {
          if (!ref) return
          connectors.create(ref as HTMLElement, () => {
            return createFromTemplate(section_template.node_tree as TemplateNodeTree, query)
          })
        }}
        className="toolbox-item"
        position="relative"
        tabIndex={0}
        role="button"
        onClick={handleAddSection.bind(null, section_template.id)}
        onKeyDown={handleAddSectionKey.bind(null, section_template.id)}
      >
        <Flex as="div" direction="column" gap="mediumSmall">
          <div>
            <Text as="div" weight="bold">
              {section_template.name}
            </Text>
            <Text as="div">{I18n.t('Section Type')}</Text>
          </div>
          <div style={{border: '1px dotted #ababab'}}>
            <img src={section_template.thumbnail} alt="" className="section-thumbnail" />
          </div>
          <Text as="div">{section_template.description}</Text>
        </Flex>
        {templateEditor && section_template.template_category !== 'global' ? (
          <EditTemplateButtons
            templateId={section_template.id}
            onEditTemplate={onEditTemplate}
            onDeleteTemplate={onDeleteTemplate}
          />
        ) : null}
      </View>
    )
  }

  const renderSections = () => {
    return templates
      .filter(template => template.template_type === 'section')
      .filter(template => {
        if (
          template.workflow_state !== 'active' &&
          template.template_category === 'global' &&
          templateEditor === TemplateEditor.LOCAL
        ) {
          return false
        }
        return true
      })
      .sort((a, b) => {
        if (a.name === 'Blank') {
          return -1
        } else if (b.name === 'Blank') {
          return 1
        }
        return a.name.localeCompare(b.name)
      })
      .map(template => {
        return renderSection(template)
      })
  }
  return (
    <View as="div" data-testid="sections-panel">
      <Flex direction="column" gap="small" data-testid="list-o-sections">
        {renderSections()}
      </Flex>
    </View>
  )
}

export {SectionsPanel}
