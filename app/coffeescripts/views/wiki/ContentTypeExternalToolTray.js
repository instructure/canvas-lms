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
import {string, number, shape, func} from 'prop-types'
import CanvasTray from 'jsx/shared/components/CanvasTray'

const iframeStyle = {
  border: 'none',
  width: '100%',
  height: '100%',
  position: 'absolute'
}

const toolShape = shape({
  id: number.isRequired,
  title: string.isRequired,
  base_url: string.isRequired,
  icon_url: string
})

ContentTypeExternalToolTray.propTypes = {
  tool: toolShape,
  onDismiss: func
}

export default function ContentTypeExternalToolTray({tool, onDismiss}) {
  const iframeUrl = tool.base_url + '&display=borderless'

  return (
    <CanvasTray open label={tool.title} onDismiss={onDismiss} placement="end" size="regular">
      <iframe style={iframeStyle} src={iframeUrl} title={tool.title} data-lti-launch="true" />
    </CanvasTray>
  )
}
