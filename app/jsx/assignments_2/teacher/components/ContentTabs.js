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
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import {TeacherAssignmentShape} from '../assignmentData'
import Details from './Details'

ContentTabs.propTypes = {
  assignment: TeacherAssignmentShape.isRequired
}

export default function ContentTabs(props) {
  const {assignment} = props
  return (
    <TabList defaultSelectedIndex={0} variant="minimal">
      <TabPanel title="Details">
        <Details assignment={assignment} />
      </TabPanel>
      <TabPanel title="Students">Students</TabPanel>
      <TabPanel title="Rubric">Rubric</TabPanel>
      <TabPanel title="Settings">Settings</TabPanel>
    </TabList>
  )
}
