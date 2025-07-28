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

import React from 'react'
import ItemAssignToTray, {type ItemAssignToTrayProps} from './ItemAssignToTray'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

export default function ItemAssignToManager({
  open,
  onSave,
  onChange,
  onClose,
  onExited,
  onDismiss,
  courseId,
  itemName,
  itemType,
  iconType,
  itemContentId,
  defaultGroupCategoryId,
  pointsPossible,
  initHasModuleOverrides,
  locale,
  timezone,
  defaultCards,
  defaultDisabledOptionIds,
  onAddCard,
  onAssigneesChange,
  onDatesChange,
  onCardRemove,
  defaultSectionId,
  useApplyButton,
  removeDueDateInput,
  isCheckpointed,
  onInitialStateSet,
  postToSIS,
  isTray,
  setOverrides,
}: ItemAssignToTrayProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <ItemAssignToTray
        open={open}
        onSave={onSave}
        onChange={onChange}
        onClose={onClose}
        onExited={onExited}
        onDismiss={onDismiss}
        courseId={courseId}
        itemName={itemName}
        itemType={itemType}
        iconType={iconType}
        itemContentId={itemContentId}
        defaultGroupCategoryId={defaultGroupCategoryId}
        pointsPossible={pointsPossible}
        initHasModuleOverrides={initHasModuleOverrides}
        locale={locale}
        timezone={timezone}
        defaultCards={defaultCards}
        defaultDisabledOptionIds={defaultDisabledOptionIds}
        onAddCard={onAddCard}
        onAssigneesChange={onAssigneesChange}
        onDatesChange={onDatesChange}
        onCardRemove={onCardRemove}
        defaultSectionId={defaultSectionId}
        useApplyButton={useApplyButton}
        removeDueDateInput={removeDueDateInput}
        isCheckpointed={isCheckpointed}
        onInitialStateSet={onInitialStateSet}
        postToSIS={postToSIS}
        isTray={isTray}
        setOverrides={setOverrides}
      />
    </QueryClientProvider>
  )
}
