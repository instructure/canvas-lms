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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {ApplyLocale} from '@instructure/ui-i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Mask} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {Tray} from '@instructure/ui-tray'
import {uid} from '@instructure/uid'
import {View} from '@instructure/ui-view'
import {
  IconAddLine,
  IconAssignmentLine,
  IconQuizLine,
  IconQuizSolid,
  IconQuestionLine,
} from '@instructure/ui-icons'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {BaseDateDetails, FetchDueDatesResponse} from './types'
import ItemAssignToCard from './ItemAssignToCard'
import TrayFooter from '../Footer'

const I18n = useI18nScope('differentiated_modules')

function itemTypeToIcon(itemType: string) {
  switch (itemType) {
    case 'assignment':
      return <IconAssignmentLine />
    case 'quiz':
      return <IconQuizLine />
    case 'lti-quiz':
      return <IconQuizSolid />
    default:
      return <IconQuestionLine />
  }
}

function itemTypeToApiURL(courseId: string, itemType: string, itemId: string) {
  switch (itemType) {
    case 'assignment':
    case 'lti-quiz':
      return `/api/v1/courses/${courseId}/assignments/${itemId}/date_details`
    case 'quiz':
      return `/api/v1/courses/${courseId}/quizzes/${itemId}/date_details`
    default:
      return ''
  }
}

function makeCardId(): string {
  return uid('assign-to-card', 3)
}

// TODO: need props to initialize with cards corresponding to current assignments
export interface ItemAssignToTrayProps {
  open: boolean
  onClose: () => void
  onDismiss: () => void
  onSave: () => void
  courseId: string
  moduleItemId: string
  moduleItemName: string
  moduleItemType: string
  moduleItemContentType: string
  moduleItemContentId: string
  pointsPossible: string
  locale: string
  timezone: string
}

// TODO: will eventually be ItemAssignToCardSpec, I think
interface CardSpec {
  isValid: boolean
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
}
interface CardMap {
  [key: string]: CardSpec
}

export default function ItemAssignToTray({
  open,
  onClose,
  onDismiss,
  onSave,
  courseId,
  moduleItemId,
  moduleItemName,
  moduleItemType,
  moduleItemContentType,
  moduleItemContentId,
  pointsPossible,
  locale,
  timezone,
}: ItemAssignToTrayProps) {
  const [assignToCards, setAssignToCards] = useState<CardMap>({})
  const [fetchInFlight, setFetchInFlight] = useState(false)

  useEffect(() => {
    setFetchInFlight(true)
    doFetchApi({
      path: itemTypeToApiURL(courseId, moduleItemType, moduleItemContentId),
    })
      .then((response: FetchDueDatesResponse) => {
        // TODO: exhaust pagination
        const dateDetailsApiResponse = response.json
        const overrides = dateDetailsApiResponse.overrides
        delete dateDetailsApiResponse.overrides
        const baseDates: BaseDateDetails = dateDetailsApiResponse

        const cards: CardMap = {}
        if ('id' in dateDetailsApiResponse) {
          const cardId = makeCardId()
          cards[cardId] = {
            isValid: true,
            due_at: baseDates.due_at,
            unlock_at: baseDates.unlock_at,
            lock_at: baseDates.lock_at,
          }
        }
        if (overrides?.length) {
          overrides.forEach(override => {
            const cardId = makeCardId()
            cards[cardId] = {
              isValid: true,
              due_at: override.due_at,
              unlock_at: override.unlock_at,
              lock_at: override.lock_at,
            }
          })
        }
        setAssignToCards(cards)
      })
      .catch(showFlashError())
      .finally(() => {
        setFetchInFlight(false)
      })
  }, [courseId, moduleItemContentId, moduleItemContentType, moduleItemId, moduleItemType])

  const handleAddCard = useCallback(() => {
    const cardId = makeCardId()
    setAssignToCards({...assignToCards, [cardId]: {isValid: true}} as any)
  }, [assignToCards])

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

  const handleCardValidityChange = useCallback(
    (cardId: string, isValid: boolean) => {
      const cards = {...assignToCards}
      cards[cardId].isValid = isValid
      setAssignToCards(cards)
    },
    [assignToCards]
  )

  const allCardsValid = useCallback(() => {
    return Object.values(assignToCards).every(card => card.isValid)
  }, [assignToCards])

  function Header() {
    const icon = itemTypeToIcon(moduleItemType)
    return (
      <Flex.Item margin="medium 0" padding="0 medium" width="100%">
        <CloseButton
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
        />
        <Heading as="h3">
          {icon} {moduleItemName}
        </Heading>
        <View data-testid="item-type-text" as="div" margin="medium 0 0 0">
          {renderItemType()} {pointsPossible ? `| ${pointsPossible}` : ''}
        </View>
      </Flex.Item>
    )
  }

  function renderItemType() {
    switch (moduleItemType) {
      case 'assignment':
        return I18n.t('Assignment')
      case 'quiz':
        return I18n.t('Quiz')
      case 'lti-quiz':
        return I18n.t('Quiz')
      default:
        return ''
    }
  }

  function renderCards() {
    const cardIds = Object.keys(assignToCards)
    const cardCount = cardIds.length
    return cardIds.map(cardId => {
      const dateProps = assignToCards[cardId]
      return (
        <View key={cardId} as="div" margin="small 0 0 0">
          <ItemAssignToCard
            cardId={cardId}
            due_at={dateProps.due_at}
            unlock_at={dateProps.unlock_at}
            lock_at={dateProps.lock_at}
            onDelete={cardCount === 1 ? undefined : handleDeleteCard}
            onValidityChange={handleCardValidityChange}
          />
        </View>
      )
    })
  }

  function Body() {
    return (
      <Flex.Item padding="small medium 0" shouldGrow={true} shouldShrink={true}>
        {fetchInFlight && (
          <Mask>
            <Spinner renderTitle={I18n.t('Loading')} />
          </Mask>
        )}
        <ApplyLocale locale={locale} timezone={timezone}>
          {renderCards()}
        </ApplyLocale>

        <Button onClick={handleAddCard} margin="small 0 0 0" renderIcon={IconAddLine}>
          {I18n.t('Add')}
        </Button>
      </Flex.Item>
    )
  }

  function Footer() {
    return (
      <Flex.Item margin="small 0 0 0" width="100%">
        <TrayFooter
          updateInteraction={allCardsValid() ? 'enabled' : 'inerror'}
          saveButtonLabel={I18n.t('Save')}
          onDismiss={onDismiss}
          onUpdate={handleUpdate}
        />
      </Flex.Item>
    )
  }

  return (
    <Tray
      data-testid="module-item-edit-tray"
      onClose={onClose}
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
