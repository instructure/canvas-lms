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

import React, {useCallback, useState} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconCopyLine,
  IconDownloadLine,
  IconEditLine,
  IconLinkLine,
  IconMoreLine,
  IconResetLine,
  IconReviewScreenLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import type {MenuItemProps} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ViewOwnProps} from '@instructure/ui-view'

const PORTFOLIO_CARD_WIDTH = '400px'
const PORTFOLIO_CARD_HEIGHT = '200px'
const PORTFOLIO_CARD_IMAGE_HEIGHT = `${200 - 96}px`

export type PortfolioCardProps = {
  id: string
  title: string
  heroImageUrl?: string | null
  onAction: (portfolioId: string, action: string) => void
}

const PortfolioCard = ({id, title, heroImageUrl, onAction}: PortfolioCardProps) => {
  const [kabobButtonRef, setKabobButtonRef] = useState<Element | null>(null)

  const handleKabobMenuSelect = useCallback(
    (
      e: React.MouseEvent<Element, MouseEvent>,
      value: MenuItemProps['value'] | MenuItemProps['value'][]
    ) => {
      e.preventDefault()
      e.stopPropagation()
      if (!value) return
      if (typeof value !== 'string') return
      onAction(id, value)
    },
    [id, onAction]
  )

  const handleCardClick = useCallback(
    (e: React.MouseEvent<ViewOwnProps, MouseEvent>) => {
      if (e.target === kabobButtonRef) return
      onAction(id, 'view')
    },
    [id, kabobButtonRef, onAction]
  )

  return (
    <View
      id={`portfolio-${id}`}
      as="div"
      background="secondary"
      width={PORTFOLIO_CARD_WIDTH}
      height={PORTFOLIO_CARD_HEIGHT}
      role="button"
      cursor="pointer"
      onClick={handleCardClick}
    >
      <View as="div" height={PORTFOLIO_CARD_IMAGE_HEIGHT} overflowY="hidden">
        {heroImageUrl ? (
          <Img
            src={heroImageUrl}
            alt="Cover image"
            constrain="cover"
            height={PORTFOLIO_CARD_IMAGE_HEIGHT}
          />
        ) : (
          <div
            style={{
              width: '100%',
              height: PORTFOLIO_CARD_IMAGE_HEIGHT,
              background:
                'repeating-linear-gradient(45deg, #cecece, #cecece 10px, #aeaeae 10px, #aeaeae 20px)',
            }}
          />
        )}
      </View>
      <Flex as="div">
        <Flex.Item shouldGrow={true} padding="small small 0 small">
          <Text weight="bold" size="large">
            {title}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Menu
            onSelect={handleKabobMenuSelect}
            placement="bottom"
            trigger={
              <IconButton
                elementRef={(el: Element | null) => setKabobButtonRef(el)}
                screenReaderLabel="More"
                withBackground={false}
                withBorder={false}
              >
                <IconMoreLine />
              </IconButton>
            }
          >
            <Menu.Item value="view">
              <IconReviewScreenLine /> View
            </Menu.Item>
            <Menu.Item value="edit">
              <IconEditLine /> Edit
            </Menu.Item>
            <Menu.Item value="duplicate">
              <IconCopyLine /> Duplicate
            </Menu.Item>
            <Menu.Item value="download">
              <IconDownloadLine /> Download
            </Menu.Item>
            <Menu.Item value="rename">
              <IconEditLine /> Rename
            </Menu.Item>
            <Menu.Item value="share">
              <IconLinkLine /> Copy share link
            </Menu.Item>
            <Menu.Item value="regen_share">
              <IconResetLine /> Regenerate share link
            </Menu.Item>
            <Menu.Item value="delete">
              <IconTrashLine /> Delete
            </Menu.Item>
          </Menu>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default PortfolioCard
export {PORTFOLIO_CARD_HEIGHT, PORTFOLIO_CARD_WIDTH}
