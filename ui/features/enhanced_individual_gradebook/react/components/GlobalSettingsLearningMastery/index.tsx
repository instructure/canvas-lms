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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import React from 'react'
import {
  type GradebookOptions,
  type HandleCheckboxChange,
  type SectionConnection,
} from '../../../types'
import GradebookScoreExport from '../GlobalSettings/GradebookScoreExport'
import HideStudentNamesCheckbox from '../GlobalSettings/HideStudentNamesCheckbox'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  sections: SectionConnection[]
  gradebookOptions: GradebookOptions
  onSectionChange: (sectionId?: string) => void
  handleCheckboxChange: HandleCheckboxChange
}

export default function GlobalSettings({
  sections,
  gradebookOptions,
  onSectionChange,
  handleCheckboxChange,
}: Props) {
  const handleSectionChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const index = event.target.selectedIndex
    const sectionId = index !== 0 ? event.target.value : undefined
    onSectionChange(sectionId)
  }

  return (
    <>
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <h2>{I18n.t('Global Settings')}</h2>
        </View>
      </View>

      <View as="div" className="row-fluid" data-testid="learning-mastery-section-select">
        <View as="div" className="span4">
          <label htmlFor="section_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Select a section')}
          </label>
        </View>
        <View as="div" className="span8">
          <select id="section_select" className="section_select" onChange={handleSectionChange}>
            <option value="-1">{I18n.t('All Sections')}</option>
            {sections.map(section => (
              <option key={section.id} value={section.id}>
                {section.name}
              </option>
            ))}
          </select>
        </View>
      </View>

      <View as="div" className="row-fluid pad-box bottom-only">
        {/* {{!-- Intentionally left empty so this scales to smaller screens --}} */}
        <View as="div" className="span4" />
        <View as="div" className="span8">
          <HideStudentNamesCheckbox
            handleCheckboxChange={handleCheckboxChange}
            hideStudentNames={gradebookOptions.customOptions.hideStudentNames}
          />
        </View>
      </View>

      <View as="div" className="row-fluid">
        {/* {{!-- Intentionally left empty so this scales to smaller screens --}} */}
        <View as="div" className="span4" />
        <View as="div" className="span8">
          <GradebookScoreExport
            lastGeneratedCsvAttachmentUrl={gradebookOptions?.lastGeneratedCsvAttachmentUrl}
            gradebookCsvProgress={gradebookOptions.gradebookCsvProgress}
            userId={gradebookOptions.userId}
            exportGradebookCsvUrl={gradebookOptions.exportGradebookCsvUrl}
          />
          <View as="div" className="pad-box bottom-only">
            <View as="div">
              {gradebookOptions.publishToSisEnabled && gradebookOptions.publishToSisUrl && (
                <Link href={gradebookOptions.publishToSisUrl} isWithinText={false}>
                  {I18n.t('Sync grades to SIS')}
                </Link>
              )}
            </View>
          </View>
        </View>
      </View>
    </>
  )
}
