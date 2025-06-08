/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, func} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tabs} from '@instructure/ui-tabs'
import {TeacherAssignmentShape} from '../assignmentData'
import Details from './Details'
import StudentsSearcher from './StudentsTab/StudentsSearcher'
import {Img} from '@instructure/ui-img'

const I18n = createI18nScope('assignments_2')

ContentTabs.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  onMessageStudentsClick: func.isRequired,
  onChangeAssignment: func.isRequired,
  onValidate: func.isRequired,
  invalidMessage: func.isRequired,
  readOnly: bool,
}

export default function ContentTabs(props) {
  const {
    assignment,
    onMessageStudentsClick,
    onChangeAssignment,
    onValidate,
    invalidMessage,
    readOnly = false,
  } = props
  const [tab, setTab] = useState('tab-panel-details')

  function changeTab(_ev, {id}) {
    setTab(id)
  }

  return (
    <Tabs onRequestTabChange={changeTab}>
      <Tabs.Panel
        renderTitle={I18n.t('Details')}
        id="tab-panel-details"
        isSelected={tab === 'tab-panel-details'}
      >
        <Details
          assignment={assignment}
          onChangeAssignment={onChangeAssignment}
          onValidate={onValidate}
          invalidMessage={invalidMessage}
          readOnly={readOnly}
        />
      </Tabs.Panel>
      <Tabs.Panel
        renderTitle={I18n.t('Grading')}
        id="tab-panel-grading"
        isSelected={tab === 'tab-panel-grading'}
      >
        <div style={{width: '680px'}}>
          <Img src="/images/assignments2_grading_static.png" />
        </div>
      </Tabs.Panel>
      <Tabs.Panel
        renderTitle={I18n.t('Rubric')}
        id="tab-panel-rubric"
        isSelected={tab === 'tab-panel-rubric'}
      >
        <div style={{width: '730px'}}>
          <Img src="/images/assignments2_rubric_static.png" />
        </div>
      </Tabs.Panel>
      <Tabs.Panel
        renderTitle={I18n.t('Students')}
        id="tab-panel-students"
        isSelected={tab === 'tab-panel-students'}
      >
        <StudentsSearcher onMessageStudentsClick={onMessageStudentsClick} assignment={assignment} />
      </Tabs.Panel>
    </Tabs>
  )
}
