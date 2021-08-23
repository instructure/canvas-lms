//
// Copyright (C) 2019 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under the
// terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {arrayOf, oneOf, bool, string, shape, func} from 'prop-types'
import CanvasTray from './Tray'
import $ from 'jquery'

const toolShape = shape({
  id: string.isRequired,
  title: string.isRequired,
  base_url: string.isRequired,
  icon_url: string
})

const moduleShape = shape({
  id: string.isRequired,
  name: string.isRequired
})

const knownResourceTypes = [
  'assignment',
  'assignment_group',
  'audio',
  'discussion_topic',
  'document',
  'image',
  'module',
  'quiz',
  'page',
  'video'
]

ContentTypeExternalToolTray.propTypes = {
  tool: toolShape,
  placement: string.isRequired,
  acceptedResourceTypes: arrayOf(oneOf(knownResourceTypes)).isRequired,
  targetResourceType: oneOf(knownResourceTypes).isRequired,
  allowItemSelection: bool.isRequired,
  selectableItems: arrayOf(moduleShape).isRequired,
  onDismiss: func,
  open: bool
}

export default function ContentTypeExternalToolTray({
  tool,
  placement,
  acceptedResourceTypes,
  targetResourceType,
  allowItemSelection,
  selectableItems,
  onDismiss,
  open
}) {
  const queryParams = {
    com_instructure_course_accept_canvas_resource_types: acceptedResourceTypes,
    com_instructure_course_canvas_resource_type: targetResourceType,
    com_instructure_course_allow_canvas_resource_selection: allowItemSelection,
    com_instructure_course_available_canvas_resources: selectableItems,
    display: 'borderless',
    placement
  }
  const prefix = tool?.base_url.indexOf('?') === -1 ? '?' : '&'
  const iframeUrl = `${tool?.base_url}${prefix}${$.param(queryParams)}`
  const title = tool ? tool.title : ''
  return (
    <CanvasTray
      open={open}
      label={title}
      onDismiss={onDismiss}
      placement="end"
      size="regular"
      padding="0"
      headerPadding="medium"
    >
      <iframe
        style={{border: 'none', display: 'block', width: '100%', height: '100%'}}
        data-testid="ltiIframe"
        src={iframeUrl}
        title={title}
        data-lti-launch="true"
      />
    </CanvasTray>
  )
}
