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
import {arrayOf, string} from 'prop-types'
import {ExternalTool} from '../../graphqlData/ExternalTool'
import React from 'react'

import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'

const iframeContainerStyle = {
  maxWidth: '1366px',
  height: '0',
  paddingBottom: '55%',
  position: 'relative'
}

const iframeStyle = {
  border: 'none',
  width: '100%',
  height: '100%',
  position: 'absolute'
}

const Tools = props => (
  <TabList defaultSelectedIndex={0} variant="minimal">
    {props.tools.map(tool => (
      <TabPanel title={tool.name} key={tool._id}>
        <div style={iframeContainerStyle}>
          <iframe
            style={iframeStyle}
            src={launchUrl(props.assignmentID, props.courseID, tool)}
            title={tool.name}
          />
        </div>
      </TabPanel>
    ))}
  </TabList>
)
Tools.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired,
  tools: arrayOf(ExternalTool.shape)
}

const launchUrl = (assignmentID, courseID, tool) => {
  return `${window.location.origin}/courses/${courseID}/external_tools/${tool._id}/resource_selection?launch_type=homework_submission&assignment_id=${assignmentID}`
}

export default Tools
