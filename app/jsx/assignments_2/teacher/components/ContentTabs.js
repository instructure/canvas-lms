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

import React from 'react'
import {bool, func} from 'prop-types'
import I18n from 'i18n!assignments_2'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import {TeacherAssignmentShape} from '../assignmentData'
import Details from './Details'
import Students from './Students'

ContentTabs.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  onChangeAssignment: func.isRequired,
  onValidate: func.isRequired,
  readOnly: bool
}

ContentTabs.defaultProps = {
  readOnly: false
}

export default function ContentTabs(props) {
  const {assignment} = props
  return (
    <TabList defaultSelectedIndex={0} variant="minimal">
      <TabPanel title="Details">
        <Details
          assignment={assignment}
          onChangeAssignment={props.onChangeAssignment}
          onValidate={props.onValidate}
          readOnly={props.readOnly}
        />
      </TabPanel>
      <TabPanel title={I18n.t('Grading')}>Grading</TabPanel>
      <TabPanel title={I18n.t('Rubric')}>Rubric</TabPanel>
      <TabPanel title={I18n.t('Students')}>
        <Students assignment={assignment} />
      </TabPanel>
    </TabList>
  )
}
