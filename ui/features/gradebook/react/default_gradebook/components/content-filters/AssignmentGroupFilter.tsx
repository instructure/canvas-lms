/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import ContentFilter from '@canvas/gradebook-content-filters/react/ContentFilter'

const I18n = createI18nScope(
  'gradebook_default_gradebook_components_content_filters_assignment_group_filter',
)

const ALL_ITEMS_ID = '0'

interface AssignmentGroup {
  id: string
  name: string
}

interface AssignmentGroupFilterProps {
  assignmentGroups: AssignmentGroup[]
  selectedAssignmentGroupId?: string | null
  disabled?: boolean
  onSelect?: (id: string) => void
}

export default function AssignmentGroupFilter({
  assignmentGroups,
  selectedAssignmentGroupId = null,
  disabled = false,
  onSelect,
}: AssignmentGroupFilterProps) {
  return (
    <ContentFilter
      disabled={disabled}
      onSelect={onSelect || (() => {})}
      allItemsId={ALL_ITEMS_ID}
      allItemsLabel={I18n.t('All Assignment Groups')}
      items={assignmentGroups}
      label={I18n.t('Assignment Group Filter')}
      selectedItemId={selectedAssignmentGroupId || ALL_ITEMS_ID}
      sortAlphabetically={true}
    />
  )
}
