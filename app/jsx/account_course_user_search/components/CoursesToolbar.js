/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {arrayOf, string, bool, func, shape, oneOf} from 'prop-types'
import {isEqual, groupBy, map} from 'lodash'
import IconPlusLine from '@instructure/ui-icons/lib/Line/IconPlus'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Select from '@instructure/ui-core/lib/components/Select'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import I18n from 'i18n!account_course_user_search'
import preventDefault from 'compiled/fn/preventDefault'
import {propType as termsPropType} from '../store/TermsStore'
import NewCourseModal from './NewCourseModal'

function termGroup(term) {
  if (term.start_at && new Date(term.start_at) > new Date()) return 'future'
  if (term.end_at && new Date(term.end_at) < new Date()) return 'past'
  return 'active'
}

const termGroups = {
  active: I18n.t('Active Terms'),
  future: I18n.t('Future Terms'),
  past: I18n.t('Past Terms')
}

export default function CoursesToolbar({
  can_create_courses,
  terms,
  onApplyFilters,
  onUpdateFilters,
  isLoading,
  errors,
  draftFilters,
  show_blueprint_courses_checkbox,
  toggleSRMessage
}) {
  const groupedTerms = groupBy(terms.data, termGroup)
  const searchLabel =
    draftFilters.search_by === 'teacher'
      ? I18n.t('Search courses by teacher...')
      : I18n.t('Search courses...')

  return (
    <div>
      <form onSubmit={preventDefault(onApplyFilters)} disabled={isLoading}>
        <Grid vAlign="top" startAt="medium">
          <GridRow>
            <GridCol>
              <Grid colSpacing="small" rowSpacing="small" startAt="large">
                <GridRow>
                  <GridCol width="2">
                    <Select
                      label={<ScreenReaderContent>{I18n.t('Filter by term')}</ScreenReaderContent>}
                      value={draftFilters.enrollment_term_id}
                      onChange={e => onUpdateFilters({enrollment_term_id: e.target.value})}
                    >
                      <optgroup label={I18n.t('Show courses from')}>
                        <option key="all" value="">
                          {I18n.t('All Terms')}
                        </option>
                      </optgroup>
                      {map(termGroups, (label, key) =>
                        groupedTerms[key] && (
                          <optgroup key={key} label={label}>
                            {groupedTerms[key].map(term => (
                              <option key={term.id} value={term.id}>
                                {term.name}
                              </option>
                            ))}
                          </optgroup>
                      ))}
                      {terms.loading && (
                        <option disabled>{I18n.t('Loading more terms...')}</option>
                      )}
                    </Select>
                  </GridCol>
                  <GridCol width="2">
                    <Select
                      label={<ScreenReaderContent>{I18n.t('Search by')}</ScreenReaderContent>}
                      value={draftFilters.search_by}
                      onChange={e => onUpdateFilters({search_by: e.target.value})}
                    >
                      <optgroup label={I18n.t('Search by')}>
                        <option key="course" value="course">
                          {I18n.t('Course')}
                        </option>
                        <option key="teacher" value="teacher">
                          {I18n.t('Teacher')}
                        </option>
                      </optgroup>
                    </Select>
                  </GridCol>
                  <GridCol width="8">
                    <TextInput
                      type="search"
                      label={<ScreenReaderContent>{searchLabel}</ScreenReaderContent>}
                      value={draftFilters.search_term}
                      placeholder={searchLabel}
                      onChange={e => onUpdateFilters({search_term: e.target.value})}
                      onKeyUp={e => {
                        if (e.key === "Enter") {
                          toggleSRMessage(true)
                        } else {
                          toggleSRMessage(false)
                        }
                      }}
                      onBlur={ () => toggleSRMessage(true) }
                      onFocus={ () => toggleSRMessage(false) }
                      messages={errors.search_term && [{type: 'error', text: errors.search_term}]}
                    />
                  </GridCol>
                </GridRow>
                <GridRow>
                  <GridCol width="auto">
                    <Checkbox
                      checked={isEqual(draftFilters.enrollment_type, ['student'])}
                      onChange={e => onUpdateFilters({enrollment_type: e.target.checked ? ['student'] : null})}
                      label={I18n.t('Hide courses without students')}
                    />
                  </GridCol>
                  {show_blueprint_courses_checkbox &&
                    <GridCol>
                      <Checkbox
                        checked={draftFilters.blueprint}
                        onChange={e => onUpdateFilters({blueprint: e.target.checked ? true : null})}
                        label={I18n.t('Show only blueprint courses')}
                      />
                    </GridCol>
                  }
                </GridRow>
              </Grid>
            </GridCol>
            {can_create_courses && (
              <GridCol width="auto">
                <NewCourseModal terms={terms}>
                  <Button aria-label={I18n.t('Create new course')}>
                    <IconPlusLine />
                    {I18n.t('Course')}
                  </Button>
                </NewCourseModal>
              </GridCol>
            )}
          </GridRow>
        </Grid>
      </form>
    </div>
  )
}

CoursesToolbar.propTypes = {
  toggleSRMessage: func.isRequired,
  can_create_courses: bool,
  show_blueprint_courses_checkbox: bool,
  onUpdateFilters: func.isRequired,
  onApplyFilters: func.isRequired,
  isLoading: bool.isRequired,
  draftFilters: shape({
    enrollment_type: arrayOf(
      oneOf(['teacher', 'student', 'ta', 'observer', 'designer']).isRequired
    ),
    search_by: oneOf(['course', 'teacher']).isRequired,
    search_term: string.isRequired,
    enrollment_term_id: string.isRequired
  }).isRequired,
  errors: shape({search_term: string}).isRequired,
  terms: termsPropType
}

CoursesToolbar.defaultProps = {
  can_create_courses: (
    window.ENV &&
    window.ENV.PERMISSIONS &&
    window.ENV.PERMISSIONS.can_create_courses
  ),
  show_blueprint_courses_checkbox: (
    window.ENV &&
    window.ENV['master_courses?']
  ),
  terms: {
    data: [],
    loading: false
  },
  isLoading: false
}
