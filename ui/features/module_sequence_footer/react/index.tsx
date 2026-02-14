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

import axios from '@canvas/axios'
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {legacyRender} from '@canvas/react'

import SpeedGraderLink from '@canvas/speed-grader-link'
import StudentGroupFilter from '@canvas/student-group-filter'

const I18n = createI18nScope('module_sequence_footer')

interface GroupCategory {
  id: string
  name: string
  groups: Array<{
    id: string
    name: string
  }>
}

interface ModuleSequenceFooterProps {
  courseId: string
  filterSpeedGraderByStudentGroup?: boolean
  groupCategories: GroupCategory[]
  selectedStudentGroupId?: string
  speedGraderUrl: string
}

interface ModuleSequenceFooterState {
  selectedStudentGroupId: string
}

class ModuleSequenceFooter extends Component<ModuleSequenceFooterProps, ModuleSequenceFooterState> {
  constructor(props: ModuleSequenceFooterProps) {
    super(props)
    this.state = {selectedStudentGroupId: props.selectedStudentGroupId || '0'}
    this.onStudentGroupSelected = this.onStudentGroupSelected.bind(this)
  }

  onStudentGroupSelected(selectedStudentGroupId: string) {
    if (selectedStudentGroupId !== '0') {
      axios.put(`/api/v1/courses/${this.props.courseId}/gradebook_settings`, {
        gradebook_settings: {
          filter_rows_by: {
            student_group_id: selectedStudentGroupId,
          },
        },
      })

      this.setState({selectedStudentGroupId})
    }
  }

  render() {
    const disabled =
      this.props.filterSpeedGraderByStudentGroup && this.state.selectedStudentGroupId === '0'

    return (
      <>
        {this.props.filterSpeedGraderByStudentGroup && (
          <StudentGroupFilter
            categories={this.props.groupCategories}
            label={I18n.t('Select Group to Grade')}
            onChange={this.onStudentGroupSelected}
            value={this.state.selectedStudentGroupId}
          />
        )}
        <SpeedGraderLink
          className="btn button-sidebar-wide"
          disabled={!!disabled}
          disabledTip={I18n.t('Must select a student group first')}
          href={this.props.speedGraderUrl}
        />
      </>
    )
  }
}

function renderModuleSequenceFooter() {
  // @ts-expect-error - speed_grader_url is a page-specific ENV property
  if (ENV.speed_grader_url) {
    const $container = document.getElementById('speed_grader_link_container')

    legacyRender(
      <ModuleSequenceFooter
        courseId={ENV.COURSE_ID || ''}
        // @ts-expect-error - filter_speed_grader_by_student_group is page-specific
        filterSpeedGraderByStudentGroup={ENV.SETTINGS.filter_speed_grader_by_student_group}
        // @ts-expect-error - group_categories is page-specific ENV property
        groupCategories={ENV.group_categories || []}
        // @ts-expect-error - selected_student_group_id is page-specific ENV property
        selectedStudentGroupId={ENV.selected_student_group_id}
        // @ts-expect-error - speed_grader_url is page-specific ENV property
        speedGraderUrl={ENV.speed_grader_url}
      />,
      $container,
    )
  }
}

export {renderModuleSequenceFooter}
