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

import React, {useCallback, useEffect, useMemo, useRef, useState} from 'react'
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
  IconDiscussionLine,
} from '@instructure/ui-icons'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {lockLabels} from '@canvas/blueprint-courses/react/labels'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {
  BaseDateDetails,
  DateDetails,
  DateLockTypes,
  exportedOverride,
  FetchDueDatesResponse,
  ItemAssignToCardSpec,
} from './types'
import ItemAssignToCard, {type ItemAssignToCardRef} from './ItemAssignToCard'
import TrayFooter from '../Footer'
import type {AssigneeOption} from '../AssigneeSelector'
import useFetchAssignees from '../../utils/hooks/useFetchAssignees'
import {generateDateDetailsPayload, getOverriddenAssignees} from '../../utils/assignToHelper'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('differentiated_modules')

function itemTypeToIcon(iconType: string) {
  switch (iconType) {
    case 'assignment':
      return <IconAssignmentLine data-testid="icon-assignment" />
    case 'quiz':
      return <IconQuizLine data-testid="icon-quiz" />
    case 'lti-quiz':
      return <IconQuizSolid data-testid="icon-lti-quiz" />
    case 'discussion':
      return <IconDiscussionLine data-testid="icon-discussion" />
    default:
      return <IconQuestionLine data-testid="icon-unknown" />
  }
}

function itemTypeToApiURL(courseId: string, itemType: string, itemId: string) {
  switch (itemType) {
    case 'assignment':
    case 'lti-quiz':
      return `/api/v1/courses/${courseId}/assignments/${itemId}/date_details`
    case 'quiz':
      return `/api/v1/courses/${courseId}/quizzes/${itemId}/date_details`
    case 'discussion':
      return `/api/v1/courses/${courseId}/discussion_topics/${itemId}/date_details`
    default:
      return ''
  }
}

function makeCardId(): string {
  return uid('assign-to-card', 3)
}

export function getEveryoneOption(hasOverrides: boolean) {
  return {
    id: 'everyone',
    value: hasOverrides ? I18n.t('Everyone else') : I18n.t('Everyone'),
  }
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
  onSave?: (overrides: ItemAssignToCardSpec[]) => void
  onClose: () => void
  onDismiss: () => void
  courseId: string
  itemName: string
  itemType: string
  iconType: string
  itemContentId: string
  pointsPossible?: number | null
  locale: string
  timezone: string
  defaultCards?: ItemAssignToCardSpec[]
  defaultDisabledOptionIds?: string[]
  defaultSectionId?: string
  useApplyButton?: boolean
  removeDueDateInput?: boolean
  onAddCard?: () => void
  onAssigneesChange?: (
    cardId: string,
    newAssignee: Record<string, any>,
    deletedAssignee: Record<string, any>[]
  ) => void
  onDatesChange?: (cardId: string, dateType: string, newDate: string) => void
  onCardRemove?: (cardId: string) => void
}

export default function ItemAssignToTray({
  open,
  onSave,
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
  defaultCards,
  defaultDisabledOptionIds = [],
  onAddCard,
  onAssigneesChange,
  onDatesChange,
  onCardRemove,
  defaultSectionId,
  useApplyButton = false,
  removeDueDateInput = false,
}: ItemAssignToTrayProps) {
  const [assignToCards, setAssignToCards] = useState<ItemAssignToCardSpec[]>(defaultCards ?? [])
  const [initialCards, setInitialCards] = useState<ItemAssignToCardSpec[]>([])
  const [fetchInFlight, setFetchInFlight] = useState(false)
  const [disabledOptionIds, setDisabledOptionIds] = useState<string[]>(defaultDisabledOptionIds)
  const [shouldFocusCard, setShouldFocusCard] = useState<boolean>(false)
  const [blueprintDateLocks, setBlueprintDateLocks] = useState<DateLockTypes[] | undefined>(
    undefined
  )
  const cardsRefs = useRef<{[cardId: string]: ItemAssignToCardRef}>({})
  const addCardButtonRef = useRef<Element | null>(null)
  const everyoneOption = useMemo(() => {
    const hasOverrides =
      (disabledOptionIds.length === 1 && !disabledOptionIds.includes('everyone')) ||
      disabledOptionIds.length > 1 ||
      assignToCards.length > 1
    return getEveryoneOption(hasOverrides)
  }, [disabledOptionIds, assignToCards])

  const handleDismiss = useCallback(() => {
    if (defaultCards) {
      setAssignToCards(defaultCards)
    }
    onDismiss()
  }, [defaultCards, onDismiss])

  const {allOptions, isLoading, setSearchTerm} = useFetchAssignees({
    courseId,
    everyoneOption,
    checkMasteryPaths: true,
    defaultValues: [],
    onError: handleDismiss,
  })

  useEffect(() => {
    if (assignToCards.length === 0) return
    const lastCard = assignToCards.at(assignToCards.length - 1)
    if (!lastCard) return
    const lastCardRef = cardsRefs.current[lastCard.key]
    lastCardRef?.focusDeleteButton()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [assignToCards.length])

  useEffect(() => {
    if (defaultCards !== undefined) {
      setAssignToCards(defaultCards)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(defaultCards)])

  useEffect(() => {
    setDisabledOptionIds(defaultDisabledOptionIds)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(defaultDisabledOptionIds)])

  useEffect(() => {
    if (defaultCards !== undefined) {
      return
    }
    setFetchInFlight(true)
    doFetchApi({
      path: itemTypeToApiURL(courseId, itemType, itemContentId),
    })
      .then((response: FetchDueDatesResponse) => {
        // TODO: exhaust pagination
        const dateDetailsApiResponse = response.json
        const overrides = dateDetailsApiResponse.overrides
        const overriddenTargets = getOverriddenAssignees(overrides)
        delete dateDetailsApiResponse.overrides
        const baseDates: BaseDateDetails = dateDetailsApiResponse
        const onlyOverrides = !dateDetailsApiResponse.visible_to_everyone

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
            let removeCard = false
            let filteredStudents = override.student_ids
            if (override.context_module_id && override.student_ids) {
              filteredStudents = filteredStudents?.filter(
                id => !overriddenTargets?.students?.includes(id)
              )
              removeCard = override.student_ids?.length > 0 && filteredStudents?.length === 0
            }
            const studentOverrides =
              filteredStudents?.map(studentId => `student-${studentId}`) ?? []
            const defaultOptions = studentOverrides
            if (override.noop_id) {
              defaultOptions.push('mastery_paths')
            }
            if (override.course_section_id) {
              defaultOptions.push(`section-${override.course_section_id}`)
            }
            if (
              removeCard ||
              (override.context_module_id &&
                override?.course_section_id &&
                overriddenTargets?.sections?.includes(override?.course_section_id))
            ) {
              return
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
              contextModuleId: override.context_module_id,
              contextModuleName: override.context_module_name,
            })
            selectedOptionIds.push(...defaultOptions)
          })
        }
        setBlueprintDateLocks(dateDetailsApiResponse.blueprint_date_locks)
        setDisabledOptionIds(selectedOptionIds)
        setInitialCards(cards)
        setAssignToCards(cards)
      })
      .catch(() => {
        showFlashError()()
        handleDismiss()
      })
      .finally(() => {
        setFetchInFlight(false)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, itemContentId, itemType, JSON.stringify(defaultCards)])

  const handleAddCard = () => {
    if (onAddCard) {
      onAddCard()
      return
    }
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
        contextModuleId: null,
        contextModuleName: null,
        selectedAssigneeIds: [] as string[],
      } as ItemAssignToCardSpec,
    ]
    setAssignToCards(cards)
  }

  const handleUpdate = useCallback(() => {
    const hasErrors = assignToCards.some(card => !card.isValid)
    // If a card has errors it should not save and the respective card should be focused
    if (hasErrors) {
      const firstCardWithError = assignToCards.find(card => !card.isValid)
      if (!firstCardWithError) return
      const firstCardWithErrorRef = cardsRefs.current[firstCardWithError.key]

      Object.values(cardsRefs.current).forEach(c => c.showValidations())
      firstCardWithErrorRef?.focusInputs()
      return
    }

    if (onSave !== undefined) {
      onSave(assignToCards)
      return
    }
    const filteredCards = assignToCards.filter(
      card =>
        [null, undefined, ''].includes(card.contextModuleId) ||
        (card.contextModuleId !== null && card.isEdited)
    )
    const payload = generateDateDetailsPayload(filteredCards)
    updateModuleItem({
      courseId,
      moduleItemContentId: itemContentId,
      moduleItemType: itemType,
      moduleItemName: itemName,
      payload,
      onSuccess: handleDismiss,
    })
  }, [onSave, assignToCards, courseId, itemContentId, itemType, itemName, handleDismiss])

  const handleDeleteCard = useCallback(
    (cardId: string) => {
      const cardSelection =
        assignToCards.find(card => card.key === cardId)?.selectedAssigneeIds ?? []
      const newDisabled = disabledOptionIds.filter(id => !cardSelection.includes(id))
      const cards = assignToCards.filter(({key}) => key !== cardId)
      setAssignToCards(cards)
      setDisabledOptionIds(newDisabled)
      onCardRemove?.(cardId)
      if (addCardButtonRef?.current instanceof HTMLButtonElement) {
        addCardButtonRef.current.disabled = false // so it can be focused
        addCardButtonRef.current.focus()
      }
    },
    [assignToCards, disabledOptionIds, onCardRemove]
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
    const initialCard = initialCards.find(card => card.key === cardId)
    const areEquals =
      JSON.stringify(initialCard?.selectedAssigneeIds) === JSON.stringify(selectedAssigneeIds)
    const cards = assignToCards.map(card =>
      card.key === cardId
        ? {
            ...card,
            selectedAssigneeIds,
            highlightCard: !areEquals,
            isEdited: !areEquals,
            hasAssignees: assignees.length > 0,
          }
        : card
    )
    if (onAssigneesChange) {
      handleCustomAssigneesChange(cardId, assignees, deletedAssignees)
    }

    const allSelectedOptions = [...disabledOptionIds, ...assignees.map(({id}) => id)]
    const uniqueOptions = [...new Set(allSelectedOptions)]
    const newDisabled = uniqueOptions.filter(id =>
      deletedAssignees.length > 0 ? !deletedAssignees.includes(id) : true
    )

    setAssignToCards(cards)
    setDisabledOptionIds(newDisabled)
  }

  const handleCustomAssigneesChange = (
    cardId: string,
    assignees: AssigneeOption[],
    deletedAssignees: string[]
  ) => {
    const newSelectedOption = assignees.filter(
      assignee => !disabledOptionIds.includes(assignee.id)
    )[0]
    const idData = newSelectedOption?.id?.split('-')
    const isEveryoneOption = newSelectedOption?.id === everyoneOption.id
    const parsedCard =
      newSelectedOption === undefined
        ? ({} as exportedOverride)
        : ({
            id: isEveryoneOption ? defaultSectionId : idData[1],
            name: newSelectedOption.value,
          } as exportedOverride)

    if (newSelectedOption?.id === everyoneOption.id) {
      parsedCard.course_section_id = defaultSectionId
    } else if (parsedCard.id && idData[0] === 'section') {
      parsedCard.course_section_id = idData[1]
    } else if (parsedCard.id && idData[0] === 'student') {
      parsedCard.short_name = newSelectedOption.value
    } else if (idData && idData[0] === 'mastery_paths') {
      parsedCard.noop_id = '1'
    }

    const parsedDeletedCard = deletedAssignees.map(id => {
      const card = allOptions.find(a => a.id === id)
      const data = card?.id?.split('-')
      const deleted = {name: card?.value, type: data?.[0]} as exportedOverride

      if (id === everyoneOption.id) {
        deleted.course_section_id = defaultSectionId
      } else if (data?.[0] === 'section') {
        deleted.course_section_id = data[1]
      } else if (data?.[0] === 'student') {
        deleted.short_name = card?.value
        deleted.student_id = data[1]
      } else if (data?.[0] === 'mastery_paths') {
        deleted.noop_id = '1'
      }
      return deleted
    })
    onAssigneesChange?.(cardId, parsedCard, parsedDeletedCard)
  }

  const handleDatesChange = useCallback(
    (cardId: string, dateAttribute: string, dateValue: string | null) => {
      const newDate = dateValue === null ? undefined : dateValue
      const initialCard = initialCards.find(card => card.key === cardId)
      const {highlightCard, isEdited, ...currentCardProps} = assignToCards.find(
        card => card.key === cardId
      ) as ItemAssignToCardSpec
      const currentCard = {...currentCardProps, [dateAttribute]: newDate}
      const areEquals = JSON.stringify(initialCard) === JSON.stringify(currentCard)

      const newCard = {...currentCard, highlightCard: !areEquals, isEdited: !areEquals}
      const cards = assignToCards.map(card => (card.key === cardId ? newCard : card))
      setAssignToCards(cards)
      onDatesChange?.(cardId, dateAttribute, newDate ?? '')
    },
    [assignToCards, initialCards, onDatesChange]
  )

  const allCardsValid = useCallback(() => {
    return assignToCards.every(card => card.isValid)
  }, [assignToCards])

  const allCardsAssigned = useCallback(() => {
    return assignToCards.every(card => card.hasAssignees)
  }, [assignToCards])

  const renderPointsPossible = () =>
    pointsPossible === 1 ? I18n.t('1 pt') : I18n.t('%{pointsPossible} pts', {pointsPossible})

  function Header() {
    const icon = itemTypeToIcon(iconType)
    return (
      <Flex.Item margin="medium 0 small" padding="0 medium" width="100%">
        <CloseButton
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
        />
        <Heading as="h3">
          {icon} {itemName}
        </Heading>
        <View data-testid="item-type-text" as="div" margin="medium 0 0 0">
          {renderItemType()} {pointsPossible != null && `| ${renderPointsPossible()}`}
        </View>
        {blueprintDateLocks?.length > 0 ? (
          <Alert liveRegion={getLiveRegion} variant="info" margin="small 0 0">
            <Text weight="bold" size="small">
              {I18n.t('Locked: ')}
            </Text>
            <Text size="small">{blueprintDateLocks.map(i => lockLabels[i]).join(' & ')}</Text>
          </Alert>
        ) : null}
      </Flex.Item>
    )
  }

  function renderItemType() {
    switch (iconType) {
      case 'assignment':
        return I18n.t('Assignment')
      case 'quiz':
        return I18n.t('Quiz')
      case 'lti-quiz':
        return I18n.t('Quiz')
      case 'discussion':
        return I18n.t('Discussion')
      default:
        return ''
    }
  }

  function renderCards(isOpen?: boolean) {
    const cardCount = assignToCards.length
    return assignToCards.map((card, i) => {
      return (
        <View key={card.key} as="div" margin="small 0 0 0">
          <ItemAssignToCard
            ref={cardRef => {
              if (cardRef) cardsRefs.current[card.key] = cardRef
            }}
            courseId={courseId}
            contextModuleId={card.contextModuleId}
            contextModuleName={card.contextModuleName}
            removeDueDateInput={removeDueDateInput}
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
            highlightCard={card.highlightCard}
            blueprintDateLocks={blueprintDateLocks}
          />
        </View>
      )
    })
  }

  function Body() {
    return (
      <Flex.Item padding="small medium" shouldGrow={true} shouldShrink={true}>
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
          interaction={!allCardsAssigned() || !!blueprintDateLocks?.length ? 'disabled' : 'enabled'}
          elementRef={el => (addCardButtonRef.current = el)}
        >
          {I18n.t('Add')}
        </Button>
      </Flex.Item>
    )
  }

  function Footer() {
    return (
      <Flex.Item data-testid="module-item-edit-tray-footer" width="100%">
        <TrayFooter
          saveButtonLabel={useApplyButton ? I18n.t('Apply') : I18n.t('Save')}
          onDismiss={handleDismiss}
          onUpdate={handleUpdate}
          hasErrors={!allCardsValid()}
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
