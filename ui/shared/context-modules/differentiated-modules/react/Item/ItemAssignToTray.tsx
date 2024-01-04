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

import React, {useCallback, useEffect, useMemo, useState} from 'react'
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
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {
  BaseDateDetails,
  DateDetails,
  FetchDueDatesResponse,
  ItemAssignToCardSpec,
} from './types'
import ItemAssignToCard from './ItemAssignToCard'
import TrayFooter from '../Footer'
import type {AssigneeOption} from '../AssigneeSelector'
import useFetchAssignees from '../../utils/hooks/useFetchAssignees'
import {generateDateDetailsPayload} from '../../utils/assignToHelper'

const I18n = useI18nScope('differentiated_modules')

function itemTypeToIcon(iconType: string) {
  switch (iconType) {
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

export const updateModuleItem = ({
  courseId,
  moduleItemType,
  moduleItemName,
  moduleItemContentId,
  payload,
  onSuccess,
}: {
  courseId: string
  moduleItemType: string
  moduleItemName: string
  moduleItemContentId: string
  payload: DateDetails
  onSuccess: () => void
}) => {
  return doFetchApi({
    path: itemTypeToApiURL(courseId, moduleItemType, moduleItemContentId),
    method: 'PUT',
    body: payload,
  })
    .then(() => {
      showFlashAlert({
        type: 'success',
        message: I18n.t(`%{moduleItemName} updated`, {moduleItemName}),
      })
      onSuccess()
    })
    .catch((err: Error) => {
      showFlashAlert({
        err,
        message: I18n.t(`Error updating "%{moduleItemName}`, {moduleItemName}),
      })
    })
}

// TODO: need props to initialize with cards corresponding to current assignments
export interface ItemAssignToTrayProps {
  open: boolean
  onClose: () => void
  onDismiss: () => void
  courseId: string
  itemName: string
  itemType: string
  iconType: string
  itemContentId: string
  pointsPossible: string
  locale: string
  timezone: string
}

export default function ItemAssignToTray({
  open,
  onClose,
  onDismiss,
  courseId,
  itemName,
  itemType,
  iconType,
  itemContentId,
  pointsPossible,
  locale,
  timezone,
}: ItemAssignToTrayProps) {
  const [assignToCards, setAssignToCards] = useState<ItemAssignToCardSpec[]>([])
  const [fetchInFlight, setFetchInFlight] = useState(false)
  const [disabledOptionIds, setDisabledOptionIds] = useState<string[]>([])
  const everyoneOption = useMemo(
    () => getEveryoneOption(assignToCards.length > 1),
    [assignToCards.length]
  )

  const {allOptions, isLoading, setSearchTerm} = useFetchAssignees({
    courseId,
    everyoneOption,
    defaultValues: [],
    onError: onDismiss,
  })

  useEffect(() => {
    setFetchInFlight(true)
    doFetchApi({
      path: itemTypeToApiURL(courseId, itemType, itemContentId),
    })
      .then((response: FetchDueDatesResponse) => {
        // TODO: exhaust pagination
        const dateDetailsApiResponse = response.json
        const overrides = dateDetailsApiResponse.overrides
        delete dateDetailsApiResponse.overrides
        const baseDates: BaseDateDetails = dateDetailsApiResponse
        const onlyOverrides = dateDetailsApiResponse.only_visible_to_overrides

        const cards: ItemAssignToCardSpec[] = []
        const selectedOptionIds: string[] = []
        if (!onlyOverrides) {
          const cardId = makeCardId()
          const selectedOption = [getEveryoneOption(assignToCards.length > 1).id]
          cards.push({
            key: cardId,
            isValid: true,
            hasAssignees: true,
            due_at: baseDates.due_at,
            unlock_at: baseDates.unlock_at,
            lock_at: baseDates.lock_at,
            selectedAssigneeIds: selectedOption,
            overrideId: dateDetailsApiResponse.id,
          })
          selectedOptionIds.push(...selectedOption)
        }
        if (overrides?.length) {
          overrides.forEach(override => {
            const studentOverrides =
              override.student_ids?.map(studentId => `student-${studentId}`) ?? []
            const defaultOptions = studentOverrides
            if (override.course_section_id) {
              defaultOptions.push(`section-${override.course_section_id}`)
            }
            const cardId = makeCardId()
            cards.push({
              key: cardId,
              isValid: true,
              hasAssignees: true,
              due_at: override.due_at,
              unlock_at: override.unlock_at,
              lock_at: override.lock_at,
              selectedAssigneeIds: defaultOptions,
              defaultOptions,
              overrideId: override.id,
            })
            selectedOptionIds.push(...defaultOptions)
          })
        }
        setDisabledOptionIds(selectedOptionIds)
        setAssignToCards(cards)
      })
      .catch(() => {
        showFlashError()()
        onDismiss()
      })
      .finally(() => {
        setFetchInFlight(false)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, itemContentId, itemType])

  const handleAddCard = useCallback(() => {
    const cardId = makeCardId()
    const cards: ItemAssignToCardSpec[] = [
      ...assignToCards,
      {
        key: cardId,
        isValid: true,
        hasAssignees: false,
        due_at: null,
        unlock_at: null,
        lock_at: null,
        selectedAssigneeIds: [] as string[],
      } as ItemAssignToCardSpec,
    ]
    setAssignToCards(cards)
  }, [assignToCards])

  const handleUpdate = useCallback(() => {
    const payload = generateDateDetailsPayload(assignToCards)
    updateModuleItem({
      courseId,
      moduleItemContentId: itemContentId,
      moduleItemType: itemType,
      moduleItemName: itemName,
      payload,
      onSuccess: onDismiss,
    })
  }, [assignToCards, courseId, itemContentId, itemName, itemType, onDismiss])

  const handleDeleteCard = useCallback(
    (cardId: string) => {
      const cardSelection =
        assignToCards.find(card => card.key === cardId)?.selectedAssigneeIds ?? []
      const newDisabled = disabledOptionIds.filter(id => !cardSelection.includes(id))
      const cards = assignToCards.filter(({key}) => key !== cardId)
      setAssignToCards(cards)
      setDisabledOptionIds(newDisabled)
    },
    [assignToCards, disabledOptionIds]
  )

  const handleCardValidityChange = useCallback(
    (cardId: string, isValid: boolean) => {
      const cards = assignToCards.map(card => (card.key === cardId ? {...card, isValid} : card))
      setAssignToCards(cards)
    },
    [assignToCards]
  )

  const handleCardAssignment = (
    cardId: string,
    assignees: AssigneeOption[],
    deletedAssignees: string[]
  ) => {
    const selectedAssigneeIds = assignees.map(({id}) => id)
    const cards = assignToCards.map(card =>
      card.key === cardId
        ? {...card, selectedAssigneeIds, hasAssignees: assignees.length > 0}
        : card
    )
    const allSelectedOptions = [...disabledOptionIds, ...assignees.map(({id}) => id)]
    const uniqueOptions = [...new Set(allSelectedOptions)]
    const newDisabled = uniqueOptions.filter(id =>
      deletedAssignees.length > 0 ? !deletedAssignees.includes(id) : true
    )
    setAssignToCards(cards)
    setDisabledOptionIds(newDisabled)
  }

  const handleDatesChange = useCallback(
    (cardId: string, dateAttribute: string, dateValue: string | null) => {
      const cards = assignToCards.map(card =>
        card.key === cardId ? {...card, [dateAttribute]: dateValue} : card
      )
      setAssignToCards(cards)
    },
    [assignToCards]
  )

  const allCardsValid = useCallback(() => {
    return assignToCards.every(card => card.isValid)
  }, [assignToCards])

  const allCardsAssigned = useCallback(() => {
    return assignToCards.every(card => card.hasAssignees)
  }, [assignToCards])

  function Header() {
    const icon = itemTypeToIcon(iconType)
    return (
      <Flex.Item margin="medium 0" padding="0 medium" width="100%">
        <CloseButton
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
        />
        <Heading as="h3">
          {icon} {itemName}
        </Heading>
        <View data-testid="item-type-text" as="div" margin="medium 0 0 0">
          {renderItemType()} {pointsPossible ? `| ${pointsPossible}` : ''}
        </View>
      </Flex.Item>
    )
  }

  function renderItemType() {
    switch (itemType) {
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

  function getEveryoneOption(hasOverrides: boolean) {
    return {
      id: 'everyone',
      value: hasOverrides ? I18n.t('Everyone else') : I18n.t('Everyone'),
    }
  }

  function renderCards(isOpen?: boolean) {
    const cardCount = assignToCards.length
    return assignToCards.map(card => {
      return (
        <View key={card.key} as="div" margin="small 0 0 0">
          <ItemAssignToCard
            courseId={courseId}
            cardId={card.key}
            due_at={card.due_at}
            unlock_at={card.unlock_at}
            lock_at={card.lock_at}
            onDelete={cardCount === 1 ? undefined : handleDeleteCard}
            onCardAssignmentChange={handleCardAssignment}
            onCardDatesChange={handleDatesChange}
            onValidityChange={handleCardValidityChange}
            isOpen={isOpen}
            disabledOptionIds={disabledOptionIds}
            everyoneOption={everyoneOption}
            selectedAssigneeIds={card.selectedAssigneeIds}
            customAllOptions={allOptions}
            customIsLoading={isLoading}
            customSetSearchTerm={setSearchTerm}
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
          {renderCards(open)}
        </ApplyLocale>

        <Button
          onClick={handleAddCard}
          data-testid="add-card"
          margin="small 0 0 0"
          renderIcon={IconAddLine}
          disabled={!allCardsAssigned()}
        >
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
        name: itemName,
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
