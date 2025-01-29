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
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import {createRoot} from 'react-dom/client'
import type {
  DateDetailsPayload,
  ItemAssignToCardSpec,
} from '@canvas/context-modules/differentiated-modules/react/Item/types'
import {
  generateDateDetailsPayload,
  generateDefaultCard,
} from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'

const I18n = createI18nScope('pages_edit')

interface Props {
  pageName?: string
  pageId?: string
  onSync: (overrides: DateDetailsPayload) => void
}

const AssignToOption = (props: Props) => {
  const [checkPoint, setCheckPoint] = useState<ItemAssignToCardSpec[] | undefined>(undefined)
  const [disabledOptionIds, setDisabledOptionIds] = useState<string[]>([])
  const itemName =
    (document.getElementById('wikipage-title-input') as HTMLInputElement)?.value ?? props.pageName

  useEffect(() => {
    if (props.pageId === undefined) {
      const defaultCard = generateDefaultCard()
      // @ts-expect-error
      setCheckPoint([defaultCard])
      setDisabledOptionIds(defaultCard.selectedAssigneeIds)
    }
  }, [props.pageId])

  const onChange = (
    assignToCards: ItemAssignToCardSpec[],
    hasModuleOverrides: boolean,
    deletedModuleAssignees: string[],
    newDisabledOptionIds: string[],
    moduleOverrides: ItemAssignToCardSpec[],
  ) => {
    const filteredCards = assignToCards.filter(
      card =>
        [null, undefined, ''].includes(card.contextModuleId) ||
        (card.contextModuleId !== null && card.isEdited),
    )
    if (hasModuleOverrides) {
      assignToCards.forEach(card => {
        const hasUnlockOrLock = card.unlock_at != null || card.lock_at != null

        if (
          card.contextModuleId &&
          card.isEdited &&
          (hasUnlockOrLock || !card.hasInitialOverride)
        ) {
          card.contextModuleId = null
          card.contextModuleName = null
          return
        } else if (hasUnlockOrLock) {
          return
        }

        const moduleCard = moduleOverrides.find(moduleOverride => moduleOverride.key === card.key)
        if (
          moduleCard &&
          !hasUnlockOrLock &&
          (card.hasInitialOverride === undefined || card.hasInitialOverride)
        ) {
          card.contextModuleId = moduleCard.contextModuleId
          card.contextModuleName = moduleCard.contextModuleName
        }
      })
    }

    const overrides = generateDateDetailsPayload(
      filteredCards,
      hasModuleOverrides,
      deletedModuleAssignees,
    )
    props.onSync(overrides)
    setDisabledOptionIds(newDisabledOptionIds)
    return assignToCards
  }

  return (
    <View as="div" maxWidth="478px">
      <ItemAssignToManager
        data-testid="manage-assign-to"
        // @ts-expect-error
        courseId={ENV.COURSE_ID}
        itemName={itemName}
        itemType="page"
        iconType="page"
        itemContentId={props.pageId}
        useApplyButton={true}
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        removeDueDateInput={true}
        defaultCards={checkPoint}
        defaultDisabledOptionIds={disabledOptionIds}
        onInitialStateSet={setCheckPoint}
        isTray={false}
        // @ts-expect-error
        onChange={onChange}
      />
    </View>
  )
}

export const renderAssignToTray = (el: HTMLElement, props: Props) => {
  if (el) {
    const root = createRoot(el)
    root.render(<AssignToOption {...props} />)
  }
  return <AssignToOption {...props} />
}
