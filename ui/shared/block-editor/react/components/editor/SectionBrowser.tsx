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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ResourcesSection} from '../user/sections/ResourcesSection'
import {ColumnsSection} from '../user/sections/ColumnsSection'
import {HeroSection} from '../user/sections/HeroSection'
import {NavigationSection} from '../user/sections/NavigationSection'
import {AboutSection} from '../user/sections/AboutSection'
import {KnowledgeCheckSection} from '../user/sections/KnowledgeCheckSection'
import {AnnouncementSection} from '../user/sections/AnnouncementSection'
import {FooterSection} from '../user/sections/FooterSection'
import {getNodeIndex} from '../../utils'
import {type AddSectionPlacement} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const nameToSection = (name: string) => {
  switch (name) {
    case 'Callout Cards':
      return <ResourcesSection />
    case 'Blank':
      return <ColumnsSection columns={1} />
    case 'Hero':
      return <HeroSection />
    case 'Navigation':
      return <NavigationSection />
    case 'About':
      return <AboutSection />
    case 'Knowledge Check':
      // @ts-expect-error
      return <KnowledgeCheckSection />
    case 'Announcement':
      return <AnnouncementSection />
    case 'Footer':
      return <FooterSection />
    default:
      return <ColumnsSection columns={2} />
  }
}
export type SectionBrowserProps = {
  open: boolean
  where: AddSectionPlacement
  onClose: () => void
}
const SectionBrowser = ({open, where, onClose}: SectionBrowserProps) => {
  const {actions, query} = useEditor()
  const {node} = useNode((n: Node) => ({
    node: n,
  }))

  const handleAddSection = useCallback(
    (name: string, index: number) => {
      const section = nameToSection(name)
      const nodeTree = query.parseReactElement(section).toNodeTree()
      const parentId = node.data.parent || 'ROOT'
      actions.addNodeTree(nodeTree, parentId, index)
    },
    [actions, node.data.parent, query],
  )

  const handleAppendSection = useCallback(
    (name: string) => {
      const myIndex = getNodeIndex(node, query)
      handleAddSection(name, myIndex + 1)
    },
    [handleAddSection, node, query],
  )
  const handlePrependSection = useCallback(
    (name: string) => {
      const myIndex = getNodeIndex(node, query)
      handleAddSection(name, myIndex)
    },
    [handleAddSection, node, query],
  )
  const handleSelectSection = useCallback(
    (sectionName: string) => {
      if (!sectionName) return
      if (where === 'prepend') {
        handlePrependSection(sectionName)
      } else {
        handleAppendSection(sectionName)
      }
      onClose()
    },
    [handleAppendSection, handlePrependSection, onClose, where],
  )
  const handleClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const sectionName = e.currentTarget.getAttribute('data-section')
      if (sectionName) {
        handleSelectSection(sectionName)
      }
    },
    [handleSelectSection],
  )
  const handleKey = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      if (e.key === 'Enter') {
        e.stopPropagation()
        e.preventDefault()
        const sectionName = e.currentTarget.getAttribute('data-section')
        if (sectionName) {
          handleSelectSection(sectionName)
        }
      }
    },
    [handleSelectSection],
  )
  const renderBox = (name: string, thumbnail: string, description: string) => {
    return (
      <div
        role="button"
        tabIndex={0}
        data-section={name}
        onClick={handleClick}
        onKeyDown={handleKey}
        style={{cursor: 'pointer'}}
      >
        <View as="div" margin="x-small" padding="small" shadow="resting" background="secondary">
          <Flex direction="column" justifyItems="start" gap="small">
            <Heading level="h3">{name}</Heading>
            <Text size="small">{description}</Text>
            <Img src={`/images/block_editor/${thumbnail}`} alt={name} />
          </Flex>
        </View>
      </div>
    )
  }
  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="medium"
      label={I18n.t('Section Browser')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <Heading level="h2">Section Browser</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel={I18n.t('Close')} />
      </Modal.Header>
      <Modal.Body>
        <Flex gap="small" direction="column" padding="x-small">
          {renderBox(
            I18n.t('Hero'),
            'section-hero.png',
            I18n.t(
              "The hero section is the large, attention-grabbing area at the top. It's the first thing visitors see when they land on your Page, so it's crucial for making a strong first impression.",
            ),
          )}
          {renderBox(
            I18n.t('Navigation'),
            'section-navigation.png',
            I18n.t(
              'Navigation sections help visitors move around the course efficiently. Good navigation is crucial for enhancing the user experience, making it easy to find the information quickly and without frustration.',
            ),
          )}
          {renderBox(
            I18n.t('About'),
            'section-about.png',
            I18n.t('The about section is a great place to introduce yourself or your course. '),
          )}
          {renderBox(
            I18n.t('Callout Cards'),
            'section-resources.png',
            I18n.t(
              'Callout cards guide page viewers to important information. An effective callout card provides a short summary of what visitors can find along with a button or link to additional content.',
            ),
          )}
          {renderBox(
            I18n.t('Quiz'),
            'section-quiz.png',
            I18n.t('The quiz section is where you can add a quiz to your page.'),
          )}
          {renderBox(
            I18n.t('Announcement'),
            'section-announcement.png',
            I18n.t('The announcement section is where you can add an announcement to your page.'),
          )}
          {renderBox(
            I18n.t('Footer'),
            'section-footer.png',
            I18n.t(
              'The footer is the section located at the very bottom of each page. It serves several important purposes, providing additional information and functionality that complement the main content.',
            ),
          )}
          {renderBox(
            I18n.t('Blank'),
            'section-columns.png',
            I18n.t(
              'The columns section is a flexible layout that allows you to add multiple blocks side by side.',
            ),
          )}
        </Flex>
      </Modal.Body>
    </Modal>
  )
}
export {SectionBrowser}
