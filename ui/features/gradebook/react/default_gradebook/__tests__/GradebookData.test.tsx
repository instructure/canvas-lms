// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import {RequestDispatch} from '@canvas/network'
import GradebookData from '../GradebookData'
import Gradebook from '../Gradebook'
import PerformanceControls from '../PerformanceControls'
import {defaultGradebookProps} from './GradebookSpecHelper'

const defaultProps = {
  ...defaultGradebookProps,
  gradebookEnv: {
    context_id: '1',
    enhanced_gradebook_filters: false,
    course_settings: {
      allow_final_grade_override: true,
    },
    settings: {
      filter_rows_by: {
        section_id: null,
        student_group_id: null,
      },
      filter_columns_by: {
        assignment_group_id: null,
        context_module_id: null,
        grading_period_id: null,
      },
    },
  },
  performance_controls: {
    students_chunk_size: 2, // students per page
  },
}

describe('GradebookData', () => {
  it('renders', () => {
    const wrapper = shallow(<GradebookData {...defaultProps} />)
    expect(wrapper.find(Gradebook).exists()).toBeTruthy()
    expect(wrapper.prop('isFiltersLoading')).toStrictEqual(false)
    expect(wrapper.prop('isModulesLoading')).toStrictEqual(false)
    expect(wrapper.prop('modules')).toStrictEqual([])
    expect(wrapper.prop('dispatch')).toBeInstanceOf(RequestDispatch)
    expect(wrapper.prop('performanceControls')).toBeInstanceOf(PerformanceControls)
  })
})
