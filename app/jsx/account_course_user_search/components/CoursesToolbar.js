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
import {string, bool, func, shape, oneOf} from 'prop-types'
import IconPlusLine from 'instructure-icons/lib/Line/IconPlusLine'
import Button from '@instructure/ui-core/lib/components/Button'
import Checkbox from '@instructure/ui-core/lib/components/Checkbox'
import Grid, {GridCol, GridRow} from '@instructure/ui-core/lib/components/Grid'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import Select from '@instructure/ui-core/lib/components/Select'
import TextInput from '@instructure/ui-core/lib/components/TextInput'
import I18n from 'i18n!account_course_user_search'
import preventDefault from 'compiled/fn/preventDefault'
import {propType as termsPropType} from '../store/TermsStore'
import NewCourseModal from './NewCourseModal'

export default function CoursesToolbar({
  can_create_courses,
  terms,
  onApplyFilters,
  onUpdateFilters,
  isLoading,
  errors,
  draftFilters
}) {
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
                        {(terms.data || []).map(term => (
                          <option key={term.id} value={term.id}>
                            {term.name}
                          </option>
                        ))}
                        {terms.loading && (
                          <option disabled>{I18n.t('Loading more terms...')}</option>
                        )}
                      </optgroup>
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
                      messages={errors.search_term && [{type: 'error', text: errors.search_term}]}
                    />
                  </GridCol>
                </GridRow>
                <GridRow>
                  <GridCol>
                    <Checkbox
                      checked={draftFilters.with_students}
                      onChange={e => onUpdateFilters({with_students: e.target.checked})}
                      label={I18n.t('Hide courses without enrollments')}
                    />
                  </GridCol>
                </GridRow>
              </Grid>
            </GridCol>
            {can_create_courses && (
              <GridCol width="auto">
                <NewCourseModal terms={terms}>
                  <Button>
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
  can_create_courses: bool,
  onUpdateFilters: func.isRequired,
  onApplyFilters: func.isRequired,
  isLoading: bool.isRequired,
  draftFilters: shape({
    with_students: bool.isRequired,
    search_by: oneOf(['course', 'teacher']).isRequired,
    search_term: string.isRequired,
    enrollment_term_id: string.isRequired
  }).isRequired,
  errors: shape({search_term: string}).isRequired,
  terms: termsPropType
}

CoursesToolbar.defaultProps = {
  can_create_courses:
    window.ENV && window.ENV.PERMISSIONS && window.ENV.PERMISSIONS.can_create_courses,
  terms: {
    data: [],
    loading: false
  },
  isLoading: false
}
