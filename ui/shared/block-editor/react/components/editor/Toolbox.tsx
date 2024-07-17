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

import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {SVGIcon} from '@instructure/ui-svg-images'

// import {Container, ContainerIcon} from '../user/blocks/Container'
import {ButtonBlock, ButtonBlockIcon} from '../user/blocks/ButtonBlock'
import {TextBlock, TextBlockIcon} from '../user/blocks/TextBlock'
import {HeadingBlock, HeadingBlockIcon} from '../user/blocks/HeadingBlock'
import {ResourceCard, ResourceCardIcon} from '../user/blocks/ResourceCard'
import {ImageBlock, ImageBlockIcon} from '../user/blocks/ImageBlock'
import {IconBlock, IconBlockIcon} from '../user/blocks/IconBlock'
import {RCEBlock, RCEBlockIcon} from '../user/blocks/RCEBlock'

type ToolboxProps = {
  open: boolean
  container: HTMLElement
  onClose: () => void
}

export const Toolbox = ({open, container, onClose}: ToolboxProps) => {
  const {connectors} = useEditor()
  const [activeTab, setActiveTab] = useState(1)
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

  const renderBox = (label: string, icon: string, element: JSX.Element) => {
    return (
      <View
        shadow="resting"
        className="toolbox-item"
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
    <Tray
      contentRef={el => setTrayRef(el)}
      label="Toolbox"
      mountNode={document.querySelector('.block-editor-editor') as HTMLElement}
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
          {renderBox('Text', TextBlockIcon, <TextBlock text="" />)}
          {/* @ts-expect-error */}
          {window.ENV.RICH_CONTENT_AI_TEXT_TOOLS &&
            renderBox('RCE', RCEBlockIcon, <RCEBlock text="" />)}
          {renderBox('Icon', IconBlockIcon, <IconBlock iconName="apple" />)}
          {renderBox('Heading', HeadingBlockIcon, <HeadingBlock />)}
          {renderBox('Resource Card', ResourceCardIcon, <ResourceCard />)}
          {renderBox('Image', ImageBlockIcon, <ImageBlock />)}
        </Flex>
      </View>
    </Tray>
  )
}
