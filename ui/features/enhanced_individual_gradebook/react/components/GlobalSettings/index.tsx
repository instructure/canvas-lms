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
import {GradebookOptions, GradebookSortOrder, SectionConnection} from '../../../types'
import {Link} from '@instructure/ui-link'
import {Button} from '@instructure/ui-buttons'
import GradebookScoreExport from './GradebookScoreExport'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {IconUploadLine} from '@instructure/ui-icons'

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
  gradebookOptions: GradebookOptions
  onSortChange: (sortType: GradebookSortOrder) => void
  onSectionChange: (sectionId?: string) => void
}

export default function GlobalSettings({
  sections,
  gradebookOptions,
  onSortChange,
  onSectionChange,
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

  return (
    <>
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <h2>{I18n.t('Global Settings')}</h2>
        </View>
      </View>

      <View as="div" className="row-fluid">
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

      <div className="row-fluid" style={{paddingBottom: 20}}>
        <View as="div" className="span4">
          <label htmlFor="sort_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Sort Assignments')}
          </label>
        </View>
        <View as="div" className="span8">
          <select
            id="sort_select"
            className="section_select"
            defaultValue={gradebookOptions.sortOrder}
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
          <div
            className="checkbox"
            style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
          >
            <label className="checkbox" htmlFor="ungraded_checkbox">
              <input type="checkbox" id="ungraded_checkbox" name="ungraded_checkbox" />
              {I18n.t('View Ungraded as 0')}
            </label>
          </div>
          <div
            className="checkbox"
            style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
          >
            <label className="checkbox" htmlFor="hide_names_checkbox">
              <input type="checkbox" id="hide_names_checkbox" name="hide_names_checkbox" />
              {I18n.t('Hide Student Names')}
            </label>
          </div>
          <div
            className="checkbox"
            style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
          >
            <label className="checkbox" htmlFor="concluded_enrollments_checkbox">
              <input
                type="checkbox"
                id="concluded_enrollments_checkbox"
                name="concluded_enrollments_checkbox"
              />
              {I18n.t('Show Concluded Enrollments')}
            </label>
          </div>
          <div
            className="checkbox"
            style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
          >
            <label className="checkbox" htmlFor="show_notes_checkbox">
              <input type="checkbox" id="show_notes_checkbox" name="show_notes_checkbox" />
              {I18n.t('Show Notes in Student Info')}
            </label>
          </div>
          {/* {{#if finalGradeOverrideEnabled}}
            <View as="div" className="checkbox">
              <label className="checkbox">
              {{
                input
                type="checkbox"
                id="allow_final_grade_override"
                name="allow_final_grade_override"
                checked=allowFinalGradeOverride
              }}
              {{#t}}Allow Final Grade Override{{/t}}
              </label>
            </View>
          {{/if}} */}
          {/* {{#unless gradesAreWeighted}}
            <View as="div" className="checkbox">
              <label className="checkbox">
              {{
                input
                type="checkbox"
                id="show_total_as_points"
                name="show_total_as_points"
                checked=showTotalAsPoints
              }}
              {{#t "show_total_as_points"}}Show Totals as Points on Student Grade Page{{/t}}
              </label>
            </View>
          {{/unless}} */}
          <div
            className="checkbox"
            style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
          >
            <label className="checkbox" htmlFor="show_total_as_points">
              <input type="checkbox" id="show_total_as_points" name="show_total_as_points" />
              {I18n.t('Show Totals as Points on Student Grade Page')}
            </label>
          </div>
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
              {/* {{#if publishToSisEnabled}}
                <a href="{{ unbound publishToSisURL }}">
                  {{#t}}Sync grades to SIS{{/t}}
                </a>
              {{/if}} */}
            </View>
            <View as="div">
              <Link href={`${gradebookOptions.contextUrl}/gradebook/history`} isWithinText={false}>
                {I18n.t('View Gradebook History')}
              </Link>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}
