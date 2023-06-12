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
import {isEqual, groupBy, map, compact} from 'lodash'
import {IconPlusLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {Grid} from '@instructure/ui-grid'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import SearchableSelect from './SearchableSelect'
import {useScope as useI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import {propType as termsPropType} from '../store/TermsStore'
import NewCourseModal from './NewCourseModal'

const I18n = useI18nScope('account_course_user_search')

function termGroup(term) {
  if (term.start_at && new Date(term.start_at) > new Date()) return 'future'
  if (term.end_at && new Date(term.end_at) < new Date()) return 'past'
  return 'active'
}

const termGroups = {
  active: I18n.t('Active Terms'),
  future: I18n.t('Future Terms'),
  past: I18n.t('Past Terms'),
}

const allTermsGroup = (
  <SearchableSelect.Group key="allGroup" id="allGroup" label={I18n.t('Show courses from')}>
    <SearchableSelect.Option key="all" id="all" value="">
      {I18n.t('All Terms')}
    </SearchableSelect.Option>
  </SearchableSelect.Group>
)

export default function CoursesToolbar({
  can_create_courses,
  terms,
  onApplyFilters,
  onUpdateFilters,
  isLoading,
  errors,
  draftFilters,
  toggleSRMessage,
}) {
  const groupedTerms = groupBy(terms.data, termGroup)
  const searchLabel =
    draftFilters.search_by === 'teacher'
      ? I18n.t('Search courses by teacher...')
      : I18n.t('Search courses...')

  const termOptions = []
  termOptions.push(allTermsGroup)
  termOptions.push(
    ...compact(
      // Create Group options for terms and remove empty items
      map(
        termGroups,
        (label, key) =>
          groupedTerms[key] && (
            <SearchableSelect.Group key={key} id={key} label={label}>
              {groupedTerms[key].map(term => (
                <SearchableSelect.Option key={term.id} id={term.id} value={term.id}>
                  {term.name}
                </SearchableSelect.Option>
              ))}
            </SearchableSelect.Group>
          )
      )
    )
  )

  return (
    <div>
      <form onSubmit={preventDefault(onApplyFilters)} disabled={isLoading}>
        <Grid vAlign="top" startAt="medium">
          <Grid.Row>
            <Grid.Col>
              <Grid colSpacing="small" rowSpacing="small" startAt="large">
                <Grid.Row>
                  <Grid.Col width={4}>
                    <SearchableSelect
                      id="termFilter"
                      placeholder="Filter by term"
                      isLoading={terms.loading}
                      label={<ScreenReaderContent>{I18n.t('Filter by term')}</ScreenReaderContent>}
                      value={draftFilters.enrollment_term_id}
                      onChange={(e, {value}) => onUpdateFilters({enrollment_term_id: value})}
                    >
                      {termOptions}
                    </SearchableSelect>
                  </Grid.Col>
                  <Grid.Col width={2}>
                    <CanvasSelect
                      id="searchByFilter"
                      label={<ScreenReaderContent>{I18n.t('Search by')}</ScreenReaderContent>}
                      value={draftFilters.search_by || 'course'}
                      onChange={(e, value) => onUpdateFilters({search_by: value})}
                    >
                      <CanvasSelect.Group
                        key="search"
                        id="searchByGroup"
                        label={I18n.t('Search by')}
                      >
                        <CanvasSelect.Option key="course" id="course" value="course">
                          {I18n.t('Course')}
                        </CanvasSelect.Option>
                        <CanvasSelect.Option key="teacher" id="teacher" value="teacher">
                          {I18n.t('Teacher')}
                        </CanvasSelect.Option>
                      </CanvasSelect.Group>
                    </CanvasSelect>
                  </Grid.Col>
                  <Grid.Col width={6}>
                    <TextInput
                      type="search"
                      renderLabel={<ScreenReaderContent>{searchLabel}</ScreenReaderContent>}
                      value={draftFilters.search_term}
                      placeholder={searchLabel}
                      onChange={e => onUpdateFilters({search_term: e.target.value})}
                      onKeyUp={e => {
                        if (e.key === 'Enter') {
                          toggleSRMessage(true)
                        } else {
                          toggleSRMessage(false)
                        }
                      }}
                      onBlur={() => toggleSRMessage(true)}
                      onFocus={() => toggleSRMessage(false)}
                      messages={errors.search_term && [{type: 'error', text: errors.search_term}]}
                    />
                  </Grid.Col>
                </Grid.Row>
                <Grid.Row>
                  <Grid.Col width="auto">
                    <Checkbox
                      checked={isEqual(draftFilters.enrollment_type, ['student'])}
                      onChange={e =>
                        onUpdateFilters({enrollment_type: e.target.checked ? ['student'] : null})
                      }
                      label={I18n.t('Hide courses without students')}
                    />
                  </Grid.Col>
                  <Grid.Col width="auto">
                    <Checkbox
                      checked={draftFilters.blueprint}
                      onChange={e => onUpdateFilters({blueprint: e.target.checked ? true : null})}
                      label={I18n.t('Show only blueprint courses')}
                    />
                  </Grid.Col>
                  <Grid.Col width="auto">
                    <Checkbox
                      checked={draftFilters.public}
                      onChange={e => onUpdateFilters({public: e.target.checked ? true : null})}
                      label={I18n.t('Show only public courses')}
                    />
                  </Grid.Col>
                </Grid.Row>
              </Grid>
            </Grid.Col>
            {can_create_courses && (
              <Grid.Col width="auto">
                <NewCourseModal terms={terms}>
                  <Button aria-label={I18n.t('Create new course')}>
                    <IconPlusLine />
                    {I18n.t('Course')}
                  </Button>
                </NewCourseModal>
              </Grid.Col>
            )}
          </Grid.Row>
        </Grid>
      </form>
    </div>
  )
}

CoursesToolbar.propTypes = {
  toggleSRMessage: func.isRequired,
  can_create_courses: bool,
  onUpdateFilters: func.isRequired,
  onApplyFilters: func.isRequired,
  isLoading: bool.isRequired,
  draftFilters: shape({
    enrollment_type: arrayOf(
      oneOf(['teacher', 'student', 'ta', 'observer', 'designer']).isRequired
    ),
    search_by: oneOf(['course', 'teacher']).isRequired,
    search_term: string.isRequired,
    enrollment_term_id: string.isRequired,
  }).isRequired,
  errors: shape({search_term: string}).isRequired,
  terms: termsPropType,
}

CoursesToolbar.defaultProps = {
  can_create_courses:
    window.ENV && window.ENV.PERMISSIONS && window.ENV.PERMISSIONS.can_create_courses,
  terms: {
    data: [],
    loading: false,
  },
  isLoading: false,
}
