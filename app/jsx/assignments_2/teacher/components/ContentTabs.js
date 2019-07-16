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
import I18n from 'i18n!assignments_2'
import {Tabs} from '@instructure/ui-tabs'
import {TeacherAssignmentShape} from '../assignmentData'
import Details from './Details'
import StudentsSearcher from './StudentsTab/StudentsSearcher'
import {Img} from '@instructure/ui-elements'

ContentTabs.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  onMessageStudentsClick: func.isRequired,
  onChangeAssignment: func.isRequired,
  onValidate: func.isRequired,
  invalidMessage: func.isRequired,
  readOnly: bool
}

ContentTabs.defaultProps = {
  readOnly: false
}

export default function ContentTabs(props) {
  const {assignment} = props
  const {selectedTabIndex, setSelectedTabIndex} = useState(0)

  function handleTabChange(event, {index}) {
    setSelectedTabIndex(index)
  }

  return (
    <Tabs onRequestTabChange={handleTabChange} variant="default">
      <Tabs.Panel title="Details" selected={selectedTabIndex === 0}>
        <Details
          assignment={assignment}
          onChangeAssignment={props.onChangeAssignment}
          onValidate={props.onValidate}
          invalidMessage={props.invalidMessage}
          readOnly={props.readOnly}
        />
      </Tabs.Panel>
      <Tabs.Panel title={I18n.t('Grading')} selected={selectedTabIndex === 1}>
        <div style={{width: '680px'}}>
          <Img src="/images/assignments2_grading_static.png" />
        </div>
      </Tabs.Panel>
      <Tabs.Panel title={I18n.t('Rubric')} selected={selectedTabIndex === 2}>
        <div style={{width: '730px'}}>
          <Img src="/images/assignments2_rubric_static.png" />
        </div>
      </Tabs.Panel>
      <Tabs.Panel title={I18n.t('Students')} selected={selectedTabIndex === 3}>
        <StudentsSearcher
          onMessageStudentsClick={props.onMessageStudentsClick}
          assignment={assignment}
        />
      </Tabs.Panel>
    </Tabs>
  )
}
