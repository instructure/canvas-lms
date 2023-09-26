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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'
// @ts-expect-error
import {uid} from '@instructure/uid'
import {View} from '@instructure/ui-view'
import {
  IconAddLine,
  IconAssignmentLine,
  IconQuizLine,
  IconQuestionLine,
  // @ts-expect-error
} from '@instructure/ui-icons'
import ItemAssignToCard from './ItemAssignToCard'
import TrayFooter from '../Footer'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

function itemTypeToIcon(itemType: string) {
  switch (itemType) {
    case 'Assignment':
      return <IconAssignmentLine />
    case 'Quizzes::Quiz':
      return <IconQuizLine />
    default:
      return <IconQuestionLine />
  }
}

// TODO: need props to initialize with cards corresponding to current assignments
export interface ItemAssignToTrayProps {
  open: boolean
  onDismiss: () => void
  onSave: () => void
  courseId: string
  moduleItemId: string
  moduleItemName: string
  moduleItemType: string
  pointsPossible: string
}

// TODO: will eventually be ItemAssignToCardProps, I think
interface CardProps {
  courseId: string
  moduleItemId: string
}
interface CardMap {
  [key: string]: CardProps
}

export default function ItemAssignToTray({
  open,
  onDismiss,
  onSave,
  courseId,
  moduleItemId,
  moduleItemName,
  moduleItemType,
  pointsPossible,
}: ItemAssignToTrayProps) {
  const [assignToCards, setAssignToCards] = useState<CardMap>(() => {
    const cardId = uid('assign-to-card', 3)
    return {[cardId]: {courseId, moduleItemId}} as CardMap
  })

  const handleAddCard = useCallback(() => {
    const cardId = uid('assign-to-card', 3)
    setAssignToCards({...assignToCards, [cardId]: {courseId, moduleItemId}} as any)
  }, [assignToCards, courseId, moduleItemId])

  const handleUpdate = useCallback(() => {
    onSave()
  }, [onSave])

  const handleDeleteCard = useCallback(
    (cardId: string) => {
      const cards = {...assignToCards}
      delete cards[cardId]
      setAssignToCards(cards)
    },
    [assignToCards]
  )

  function Header() {
    const icon = itemTypeToIcon(moduleItemType)
    return (
      <FlexItem margin="medium 0 0 0" padding="0 medium" width="100%">
        <CloseButton
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
        />
        <Heading as="h3">
          {icon} {moduleItemName}
        </Heading>
        <View as="div" margin="medium 0 0 0">
          {renderItemType()} {pointsPossible ? `| ${pointsPossible}` : ''}
        </View>
      </FlexItem>
    )
  }

  function renderItemType() {
    switch (moduleItemType) {
      case 'Assignment':
        return I18n.t('Assignment')
      case 'Quizzes::Quiz':
        return I18n.t('Quiz')
      default:
        return ''
    }
  }

  function renderCards() {
    const cardIds = Object.keys(assignToCards)
    const cardCount = cardIds.length
    return cardIds.map(cardId => {
      const props = assignToCards[cardId]
      return (
        <View key={cardId} as="div" margin="small 0 0 0">
          <ItemAssignToCard
            {...props}
            cardId={cardId}
            onDelete={cardCount === 1 ? undefined : handleDeleteCard}
          />
        </View>
      )
    })
  }

  function Body() {
    return (
      <FlexItem padding="small medium 0" shouldGrow={true} shouldShrink={true}>
        {renderCards()}
        <Button onClick={handleAddCard} margin="small 0 0 0" renderIcon={IconAddLine}>
          {I18n.t('Add')}
        </Button>
      </FlexItem>
    )
  }

  function Footer() {
    return (
      <FlexItem margin="small 0 0 0" width="100%">
        <TrayFooter
          updateButtonLabel={I18n.t('Save')}
          onDismiss={onDismiss}
          onUpdate={handleUpdate}
        />
      </FlexItem>
    )
  }

  return (
    <Tray
      label={I18n.t('Edit assignment %{name}', {
        name: moduleItemName,
      })}
      open={open}
      placement="end"
      size="regular"
    >
      <Flex direction="column" height="100vh" width="100%">
        {Header()}
        {Body()}
        {Footer()}
      </Flex>
    </Tray>
  )
}
