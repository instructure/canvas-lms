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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {
  type CustomColumn,
  type GradebookOptions,
  GradebookSortOrder,
  type HandleCheckboxChange,
  type SectionConnection,
  type TeacherNotes,
} from '../../../types'
import {Link} from '@instructure/ui-link'
import {Button} from '@instructure/ui-buttons'
import GradebookScoreExport from './GradebookScoreExport'
import {IconUploadLine} from '@instructure/ui-icons'
import IncludeUngradedAssignmentsCheckbox from './IncludeUngradedAssignmentsCheckbox'
import HideStudentNamesCheckbox from './HideStudentNamesCheckbox'
import ShowConcludedEnrollmentsCheckbox from './ShowConcludedEnrollmentsCheckbox'
import ShowNotesColumnCheckbox from './ShowNotesColumnCheckbox'
import ShowTotalGradesAsPointsCheckbox from './ShowTotalGradeAsPointsCheckbox'
import AllowFinalGradeOverrideCheckbox from './AllowFinalGradeOverrideCheckbox'

const I18n = useI18nScope('enhanced_individual_gradebook')

type DropDownOption<T> = {
  value: T
  text: string
}

const assignmentSortOptions: DropDownOption<GradebookSortOrder>[] = [
  {value: GradebookSortOrder.AssignmentGroup, text: I18n.t('By Assignment Group and Position')},
  {value: GradebookSortOrder.Alphabetical, text: I18n.t('Alphabetically')},
  {value: GradebookSortOrder.DueDate, text: I18n.t('By Due Date')},
]

type Props = {
  sections: SectionConnection[]
  customColumns?: CustomColumn[] | null
  gradebookOptions: GradebookOptions
  onSortChange: (sortType: GradebookSortOrder) => void
  onSectionChange: (sectionId?: string) => void
  onGradingPeriodChange: (gradingPeriodId?: string) => void
  handleCheckboxChange: HandleCheckboxChange
  onTeacherNotesCreation: (teacherNotes: TeacherNotes) => void
}

export default function GlobalSettings({
  sections,
  customColumns,
  gradebookOptions,
  onGradingPeriodChange,
  onSortChange,
  onSectionChange,
  handleCheckboxChange,
  onTeacherNotesCreation,
}: Props) {
  const handleSortChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const sortType = event.target.value as GradebookSortOrder
    onSortChange(sortType)
  }

  const handleSectionChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const index = event.target.selectedIndex
    const sectionId = index !== 0 ? event.target.value : undefined
    onSectionChange(sectionId)
  }

  const handleGradePeriodChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const index = event.target.selectedIndex
    const gradingPeriodId = index !== 0 ? event.target.value : undefined
    onGradingPeriodChange(gradingPeriodId)
  }

  const {gradingPeriodSet, sortOrder: defaultSortOrder, selectedGradingPeriodId} = gradebookOptions
  return (
    <>
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <h2>{I18n.t('Global Settings')}</h2>
        </View>
      </View>

      <View as="div" className="row-fluid" data-testid="section-select">
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

      {gradingPeriodSet && (
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <label htmlFor="section_select" style={{textAlign: 'right', display: 'block'}}>
              {I18n.t('Select a Grading Period')}
            </label>
          </View>
          <View as="div" className="span8">
            <select
              id="grading_period_select"
              data-testid="grading-period-select"
              className="section_select"
              onChange={handleGradePeriodChange}
              defaultValue={selectedGradingPeriodId}
            >
              <option>{I18n.t('All Grading Periods')}</option>
              {gradingPeriodSet.grading_periods.map(gradingPeriod => (
                <option key={gradingPeriod.id} value={gradingPeriod.id}>
                  {gradingPeriod.title}
                </option>
              ))}
            </select>
          </View>
        </View>
      )}

      <div className="row-fluid" style={{paddingBottom: 20}}>
        <View as="div" className="span4">
          <label htmlFor="sort_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Sort Assignments')}
          </label>
        </View>
        <View as="div" className="span8">
          <select
            id="sort_select"
            data-testid="sort-select"
            className="section_select"
            defaultValue={defaultSortOrder}
            onChange={handleSortChange}
          >
            {assignmentSortOptions.map(option => (
              <option key={option.value} value={option.value}>
                {option.text}
              </option>
            ))}
          </select>
        </View>
      </div>

      <View as="div" className="row-fluid pad-box bottom-only">
        <View as="div" className="span4">
          {/* {{!-- Intentionally left empty so this scales to smaller screens --}} */}
        </View>
        <View as="div" className="span8">
          <IncludeUngradedAssignmentsCheckbox
            saveViewUngradedAsZeroToServer={gradebookOptions.saveViewUngradedAsZeroToServer}
            contextId={gradebookOptions.contextId}
            handleCheckboxChange={handleCheckboxChange}
            includeUngradedAssignments={gradebookOptions.customOptions.includeUngradedAssignments}
          />

          <HideStudentNamesCheckbox
            handleCheckboxChange={handleCheckboxChange}
            hideStudentNames={gradebookOptions.customOptions.hideStudentNames}
          />

          <ShowConcludedEnrollmentsCheckbox
            settingsUpdateUrl={gradebookOptions.settingsUpdateUrl}
            handleCheckboxChange={handleCheckboxChange}
            showConcludedEnrollments={gradebookOptions.customOptions.showConcludedEnrollments}
          />

          <ShowNotesColumnCheckbox
            teacherNotes={gradebookOptions.teacherNotes}
            customColumns={customColumns}
            customColumnUrl={gradebookOptions.customColumnUrl}
            customColumnsUrl={gradebookOptions.customColumnsUrl}
            reorderCustomColumnsUrl={gradebookOptions.reorderCustomColumnsUrl}
            handleCheckboxChange={handleCheckboxChange}
            showNotesColumn={gradebookOptions.customOptions.showNotesColumn}
            onTeacherNotesCreation={onTeacherNotesCreation}
          />

          {gradebookOptions.finalGradeOverrideEnabled && (
            <AllowFinalGradeOverrideCheckbox
              contextId={gradebookOptions.contextId}
              allowFinalGradeOverride={gradebookOptions.customOptions.allowFinalGradeOverride}
              handleCheckboxChange={handleCheckboxChange}
            />
          )}

          {!gradebookOptions.gradesAreWeighted && (
            <ShowTotalGradesAsPointsCheckbox
              settingUpdateUrl={gradebookOptions.settingUpdateUrl}
              showTotalGradeAsPoints={gradebookOptions.customOptions.showTotalGradeAsPoints}
              handleCheckboxChange={handleCheckboxChange}
            />
          )}
        </View>
      </View>

      <View as="div" className="row-fluid">
        <View as="div" className="span4">
          {/* {{!-- Intentionally left empty so this scales to smaller screens --}} */}
        </View>
        <View as="div" className="span8">
          <GradebookScoreExport
            lastGeneratedCsvAttachmentUrl={gradebookOptions?.lastGeneratedCsvAttachmentUrl}
            gradebookCsvProgress={gradebookOptions.gradebookCsvProgress}
            userId={gradebookOptions.userId}
            exportGradebookCsvUrl={gradebookOptions.exportGradebookCsvUrl}
          />

          <View as="div" className="pad-box bottom-only">
            <Button
              data-testid="upload-button"
              href={`${gradebookOptions.contextUrl}/gradebook_upload/new`}
              color="secondary"
              renderIcon={IconUploadLine}
              id="upload"
            >
              {I18n.t('Upload Scores (.csv)')}
            </Button>
          </View>

          <View as="div" className="pad-box bottom-only">
            <View as="div">
              {gradebookOptions.publishToSisEnabled && gradebookOptions.publishToSisUrl && (
                <Link href={gradebookOptions.publishToSisUrl} isWithinText={false}>
                  {I18n.t('Sync grades to SIS')}
                </Link>
              )}
            </View>

            <View as="div">
              <Link
                href={`${gradebookOptions.contextUrl}/gradebook/history`}
                isWithinText={false}
                data-testid="gradebook-history-link"
              >
                {I18n.t('View Gradebook History')}
              </Link>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}
