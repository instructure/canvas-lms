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

import React, {useEffect, useState} from 'react'
import {useEditor} from '@craftjs/core'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {BlockTemplate, TemplateNodeTree} from './types'
import {IconArrowStartLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {getGlobalPageTemplates} from '@canvas/block-editor/react/assets/globalTemplates'
import TemplateCardSkeleton from './components/create_from_templates/TemplateCardSekelton'
import QuickLook from './components/create_from_templates/QuickLook'
import DisplayLayoutButtons from '@canvas/block-editor/react/components/create_from_templates/DisplayLayoutButtons'

const I18n = useI18nScope('block-editor')

declare const ENV: GlobalEnv & {WIKI_PAGE: object}

export default function CreateFromTemplate(props: {course_id: string}) {
  const {actions} = useEditor()
  const [isOpen, setIsOpen] = useState<boolean>(!ENV.WIKI_PAGE)
  const [displayType, setDisplayType] = useState<'grid' | 'rows'>('grid')
  const [quickLookTemplate, setQuickLookTemplate] = useState<BlockTemplate | undefined>(undefined)
  const [blockTemplates, setBlockTemplates] = useState<BlockTemplate[]>([])
  const [blankPageTemplate, setBlankPageTemplate] = useState<BlockTemplate>(() => {
    return {node_tree: {}} as BlockTemplate
  })
  const close = () => {
    setIsOpen(false)
  }

  const loadTemplateOnRoot = (node_tree: TemplateNodeTree) => {
    actions.deserialize(JSON.stringify(node_tree.nodes))
  }

  useEffect(() => {
    if (isOpen) {
      getGlobalPageTemplates()
        .then((templates: BlockTemplate[]) => {
          const idx = templates.findIndex(template => template.id === 'blank_page')
          const blankPage = templates.splice(idx, 1)[0]
          setBlankPageTemplate(blankPage)
          setBlockTemplates(templates)
        })
        .catch((err: Error) => {
          showFlashError(I18n.t('Cannot get block custom templates'))(err)
        })
    }
  }, [isOpen])

  return (
    <Modal
      data-testid="template-chooser-modal"
      open={isOpen}
      onDismiss={close}
      size="fullscreen"
      label="Create Page"
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <Heading margin="0 0 small 0">{I18n.t('Create Page')}</Heading>
        <Text lineHeight="condensed">
          <div>
            {I18n.t(
              'Start from a blank page or select a pre-designed layout ready to be filled with your content.'
            )}
          </div>
          <div
            dangerouslySetInnerHTML={{
              __html: I18n.t('Custom layouts are available through *Design Services*', {
                wrappers: [
                  `<a href="https://learn.instructure.com/courses/5/pages/content-and-design-services" target="_blank">$1</a>`,
                ],
              }),
            }}
          />
        </Text>
        <div style={{top: '25px', right: '25px', position: 'absolute'}}>
          <Button
            onClick={() => {
              window.location.href = `/courses/${props.course_id}/pages`
            }}
            renderIcon={<IconArrowStartLine />}
          >
            {I18n.t('Back to Pages')}
          </Button>
        </div>
        <DisplayLayoutButtons displayType={displayType} setDisplayType={setDisplayType} />
      </Modal.Header>
      <Modal.Body>
        <Flex padding="small" wrap="wrap" gap="large">
          <TemplateCardSkeleton
            inLayout={displayType}
            template={blankPageTemplate}
            createAction={() => {
              if (blankPageTemplate.node_tree) {
                loadTemplateOnRoot(blankPageTemplate.node_tree)
              }
              close()
            }}
          />
          {blockTemplates.map(blockTemplate => {
            return (
              <TemplateCardSkeleton
                inLayout={displayType}
                key={blockTemplate.id}
                template={blockTemplate}
                createAction={() => {
                  if (blockTemplate.node_tree) {
                    loadTemplateOnRoot(blockTemplate.node_tree)
                  }
                  close()
                }}
                quickLookAction={() => {
                  setQuickLookTemplate(blockTemplate)
                }}
              />
            )
          })}
        </Flex>
        <QuickLook
          template={quickLookTemplate}
          close={() => {
            setQuickLookTemplate(undefined)
          }}
          customize={() => {
            if (quickLookTemplate && quickLookTemplate.node_tree) {
              loadTemplateOnRoot(quickLookTemplate.node_tree)
            }
            close()
          }}
        />
      </Modal.Body>
    </Modal>
  )
}
