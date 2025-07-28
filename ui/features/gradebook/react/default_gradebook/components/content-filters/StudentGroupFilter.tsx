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
import natcompare from '@canvas/util/natcompare'
import {useScope as createI18nScope} from '@canvas/i18n'
import ContentFilter from '@canvas/gradebook-content-filters/react/ContentFilter'

interface StudentGroup {
  id: string
  name: string
}

interface StudentGroupSet {
  id: string
  name: string
  groups: StudentGroup[]
}

interface NormalizedStudentGroupSet {
  id: string
  name: string
  children: StudentGroup[]
}

interface StudentGroupFilterProps {
  studentGroupSets: StudentGroupSet[]
  selectedStudentGroupId: string | null
  disabled: boolean
  onSelect: (id: string | null) => void
  [key: string]: any // For other ContentFilter props
}

const I18n = createI18nScope(
  'gradebook_default_gradebook_components_content_filters_student_group_filter',
)

function normalizeStudentGroupSets(
  studentGroupSets: StudentGroupSet[],
): NormalizedStudentGroupSet[] {
  return studentGroupSets.map((category: StudentGroupSet) => ({
    children: [...category.groups].sort(natcompare.byKey('name')),
    id: category.id,
    name: category.name,
  }))
}

export default function StudentGroupFilter(props: StudentGroupFilterProps) {
  const {studentGroupSets, selectedStudentGroupId, ...filterProps} = props

  return (
    <ContentFilter
      {...filterProps}
      allItemsId="0"
      allItemsLabel={I18n.t('All Student Groups')}
      items={normalizeStudentGroupSets(studentGroupSets)}
      label={I18n.t('Student Group Filter')}
      selectedItemId={selectedStudentGroupId}
      sortAlphabetically={true}
    />
  )
}
