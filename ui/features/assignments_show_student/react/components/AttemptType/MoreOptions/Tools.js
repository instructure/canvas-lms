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

import {arrayOf, bool, func, string} from 'prop-types'
import CanvasFiles from './CanvasFiles/index'
import {ExternalTool} from '@canvas/assignments/graphql/student/ExternalTool'
import I18n from 'i18n!assignments_2_MoreOptions_Tools'
import React, {useState} from 'react'
import {UserGroups} from '@canvas/assignments/graphql/student/UserGroups'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'

import {Tabs} from '@instructure/ui-tabs'

const iframeStyle = {
  border: 'none',
  width: '100%',
  height: '100%',
  position: 'absolute'
}

const tabContentStyle = {
  height: '0',
  paddingBottom: '55%',
  position: 'relative'
}

const Tools = props => {
  const [selectedIndex, setSelectedIndex] = useState(0)

  const handleTabChange = (_, {index}) => {
    setSelectedIndex(index)
  }

  return (
    <Tabs onRequestTabChange={handleTabChange} margin="xx-small 0 0 0">
      {props.renderCanvasFiles && (
        <Tabs.Panel
          isSelected={selectedIndex === 0}
          key="CanvasFiles"
          padding="xx-small 0"
          renderTitle={I18n.t('Canvas Files')}
        >
          <div style={tabContentStyle}>
            <CanvasFiles
              courseID={props.courseID}
              handleCanvasFileSelect={props.handleCanvasFileSelect}
              userGroups={props.userGroups.groups}
            />
          </div>
        </Tabs.Panel>
      )}
      {props.tools.map((tool, i) => (
        <Tabs.Panel
          isSelected={selectedIndex === (props.renderCanvasFiles ? i + 1 : i)}
          key={tool._id}
          padding="xx-small 0"
          renderTitle={tool.name}
        >
          <div style={tabContentStyle}>
            <iframe
              allow={iframeAllowances()}
              style={iframeStyle}
              src={launchUrl(props.assignmentID, props.courseID, tool)}
              title={tool.name}
            />
          </div>
        </Tabs.Panel>
      ))}
    </Tabs>
  )
}

Tools.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired,
  handleCanvasFileSelect: func,
  renderCanvasFiles: bool,
  tools: arrayOf(ExternalTool.shape),
  userGroups: UserGroups.shape
}

const launchUrl = (assignmentID, courseID, tool) => {
  return `${window.location.origin}/courses/${courseID}/external_tools/${tool._id}/resource_selection?launch_type=homework_submission&assignment_id=${assignmentID}`
}

export default Tools
