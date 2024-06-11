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

import React, {useState} from 'react'

import {View} from '@instructure/ui-view'

import SectionInput from './SectionInput'
import enrollmentName from '@canvas/handlebars-helpers/enrollmentName'
import {CloseButton} from '@instructure/ui-buttons'
import {useScope} from '@canvas/i18n'

import type {ResponseSection} from './api'

const I18n = useScope('roster_section_selector')

type ExistingSectionEnrollment = {
  id: string
  name: string
  can_be_removed: boolean
  role?: string
}

type SectionSelectorProps = {
  courseId: number
  initialSections: ExistingSectionEnrollment[]
}

const SectionSelector: React.FC<SectionSelectorProps> = ({courseId, initialSections}) => {
  const [selectedSections, setSelectedSections] = useState(initialSections)

  const exclude = selectedSections.map(section => `section_${section.id}`)

  const handleOnSelect = (section: ResponseSection) => {
    const newSelectedSection: ExistingSectionEnrollment = {
      id: section.id,
      name: section.name,
      can_be_removed: true,
    }
    setSelectedSections([...selectedSections, newSelectedSection])
  }

  return (
    <View>
      <SectionInput onSelect={handleOnSelect} courseId={courseId} exclude={exclude} />
      <ul id="user_sections">
        {selectedSections.map(section => (
          <li key={section.id} className={`${section.can_be_removed ? '' : 'cannot_remove'}`}>
            <View
              as="div"
              className="ellipsis"
              title={
                section.can_be_removed
                  ? `${section.name} - ${enrollmentName(section.role)}`
                  : I18n.t('You cannot remove this enrollment.')
              }
            >
              {section.name} - {enrollmentName(section.role)}
            </View>
            {section.can_be_removed && (
              <CloseButton
                screenReaderLabel={I18n.t('Remove user from %{sectionName}', {
                  sectionName: section.name,
                })}
                onClick={() => {
                  setSelectedSections(selectedSections.filter(s => s.id !== section.id))
                }}
              />
            )}

            <input type="hidden" name="sections[]" value={`section_${section.id}`} />
          </li>
        ))}
      </ul>
    </View>
  )
}

export default SectionSelector
