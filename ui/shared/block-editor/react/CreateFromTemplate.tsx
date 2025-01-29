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
import {useEditor} from '@craftjs/core'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CondensedButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {BlockTemplate, TemplateNodeTree} from './types'
import {IconArrowStartLine, IconSearchLine, IconXLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {getGlobalPageTemplates} from '@canvas/block-editor/react/assets/globalTemplates'
import TemplateCardSkeleton from './components/create_from_templates/TemplateCardSekeleton'
import QuickLook from './components/create_from_templates/QuickLook'
import DisplayLayoutButtons, {
  type DisplayType,
} from './components/create_from_templates/DisplayLayoutButtons'
import {TagSelect, AvailableTags} from './components/create_from_templates/TagSelect'

const I18n = createI18nScope('block-editor')

export default function CreateFromTemplate(props: {course_id: string, noBlocks: boolean }) {
  const {actions} = useEditor()
  const [isOpen, setIsOpen] = useState<boolean>(props.noBlocks)
  const [displayType, setDisplayType] = useState<DisplayType>('grid')
  const [quickLookTemplate, setQuickLookTemplate] = useState<BlockTemplate | undefined>(undefined)
  const [blockTemplates, setBlockTemplates] = useState<BlockTemplate[]>([])
  const [blankPageTemplate, setBlankPageTemplate] = useState<BlockTemplate>(() => {
    return {id: 'tmp_blank_page', name: 'blankpage', node_tree: {}} as BlockTemplate
  })
  const close = () => {
    setIsOpen(false)
  }
  const [searchString, setSearchString] = useState<string>('')
  const [selectedTags, setSelectedTags] = useState<string[]>(Object.keys(AvailableTags))
  const [foundTemplateIds, setFoundTemplateIds] = useState<string[]>([])
  const [interaction, setInteraction] = useState<'enabled' | 'disabled'>('disabled')

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
          setFoundTemplateIds(templates.map(template => template.id))
          setInteraction('enabled')
        })
        .catch((err: Error) => {
          showFlashError(I18n.t('Cannot get block custom templates'))(err)
        })
    }
  }, [isOpen])

  const filterTemplates = useCallback(
    (search: string, tags: string[]) => {
      const lcval = search.toLowerCase()
      const searchIds = new Set(
        blockTemplates
          .filter(
            template =>
              lcval.length < 3 ||
              template.name.toLowerCase().includes(lcval) ||
              template.description?.toLowerCase().includes(lcval),
          )
          .map(template => template.id),
      )
      const tagIds = new Set(
        blockTemplates
          .filter(template => {
            return tags.some(tag => {
              return template.tags?.includes(tag)
            })
          })
          .map(template => template.id),
      )
      const foundIds =
        typeof Set.prototype.intersection === 'function'
          ? Array.from(searchIds.intersection(tagIds))
          : [...searchIds].filter(x => tagIds.has(x))

      setFoundTemplateIds(foundIds)
    },
    [blockTemplates],
  )

  useEffect(() => {
    filterTemplates(searchString, selectedTags)
  }, [filterTemplates, searchString, selectedTags])

  const handleSearchChange = useCallback(
    (_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setSearchString(value)
    },
    [],
  )

  const handleClearAllFilters = useCallback(() => {
    setSelectedTags(Object.keys(AvailableTags))
  }, [])

  const handleTagsChange = useCallback((tags: string[]) => {
    setSelectedTags(tags)
  }, [])

  const handleRemovePill = useCallback(
    (tag: string) => {
      setSelectedTags(selectedTags.filter(t => t !== tag))
    },
    [selectedTags],
  )

  const renderClearSearch = () => {
    return (
      <CondensedButton
        renderIcon={<IconXLine title={I18n.t('Clear search string')} />}
        onClick={() => {
          setSearchString('')
        }}
      />
    )
  }

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
              'Start from a blank page or select a pre-designed layout ready to be filled with your content.',
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
        <Flex as="div" margin="large 0" gap="small">
          <Flex.Item shouldGrow={true}>
            <TextInput
              data-testid="template-search"
              renderBeforeInput={<IconSearchLine />}
              renderAfterInput={renderClearSearch()}
              renderLabel={<ScreenReaderContent>Search</ScreenReaderContent>}
              interaction={interaction}
              placeholder="Search"
              value={searchString}
              onChange={handleSearchChange}
            />
          </Flex.Item>
          <TagSelect
            onChange={handleTagsChange}
            selectedTags={selectedTags}
            interaction={interaction}
          />
        </Flex>
        <Flex margin="large 0" justifyItems="space-between" gap="small">
          <Flex>
            <CondensedButton onClick={handleClearAllFilters} interaction={interaction}>
              {I18n.t('Clear All Filters')}
            </CondensedButton>
            <View as="div" margin="0 0 0 small" data-testid="active-tags">
              {selectedTags.sort().map(tag => (
                <CondensedButton
                  onClick={() => handleRemovePill(tag)}
                  key={tag}
                  interaction={interaction}
                >
                  <Pill key={tag} margin="0 x-small 0 0" renderIcon={<IconXLine />}>
                    {AvailableTags[tag]}
                  </Pill>
                </CondensedButton>
              ))}
            </View>
          </Flex>
        </Flex>
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
          {blockTemplates
            .filter(
              template => foundTemplateIds.length > 0 && foundTemplateIds.includes(template.id),
            )
            .sort((a, b) => {
              return a.name.localeCompare(b.name)
            })
            .map(blockTemplate => {
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
