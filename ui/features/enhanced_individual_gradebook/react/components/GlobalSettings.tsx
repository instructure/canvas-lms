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

const I18n = useI18nScope('enhanced_individual_gradebook')

export default function GlobalSettings() {
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
          {/* TODO: Get Sections */}
          <select id="section_select" className="section_select">
            <option value="all">{I18n.t('All Sections')}</option>
            <option value="1">Section 1</option>
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
          <select id="sort_select" className="section_select" defaultValue="alpha">
            <option value="assignment_group">
              {I18n.t('assignment_order_assignment_groups', 'By Assignment Group and Position')}
            </option>
            <option value="alpha">{I18n.t('assignment_order_alpha', 'Alphabetically')}</option>
            <option value="due_date">{I18n.t('assignment_order_due_date', 'By Due Date')}</option>
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
          <View as="div" className="pad-box bottom-only">
            <button type="button" className="btn" id="gradebook-export">
              <i className="icon-download" />
              {I18n.t('Download Current Scores (.csv)')}
            </button>
            {/* {{#if lastGeneratedCsvAttachmentUrl}}
              <a aria-label="{{unbound lastGeneratedCsvLabel}}" href="{{unbound lastGeneratedCsvAttachmentUrl}}" id="last-exported-gradebook">
                {{unbound lastGeneratedCsvLabel}}
              </a>
            {{/if}} */}
          </View>

          <View as="div" className="pad-box bottom-only">
            <a id="upload" className="btn" href="{{unbound uploadCsvUrl}}">
              <i className="icon-upload" />
              {I18n.t('Upload Scores (.csv)')}
            </a>
          </View>
          {/* <iframe style="display:none" id="gradebook-export-iframe"></iframe> */}
          <View as="div" className="pad-box bottom-only">
            <View as="div">
              {/* {{#if publishToSisEnabled}}
                <a href="{{ unbound publishToSisURL }}">
                  {{#t}}Sync grades to SIS{{/t}}
                </a>
              {{/if}} */}
            </View>
            <View as="div">
              <a href="{{ unbound gradingHistoryUrl }}">{I18n.t('View Gradebook History')}</a>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}
