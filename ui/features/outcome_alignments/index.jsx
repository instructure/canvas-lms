/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {View} from '@instructure/ui-view'
import ready from '@instructure/ready'

import {AlignmentWidget} from '@instructure/outcomes-ui'

ready(() => {
  const container = document.getElementById('canvas_outcomes_alignment_widget')
  if (ENV.canvas_outcomes && ENV.canvas_outcomes.host) {
    ReactDOM.render(
      <View as="div" borderWidth="small none none none" padding="medium none">
        <AlignmentWidget
          host={ENV.canvas_outcomes.host}
          jwt={ENV.canvas_outcomes.jwt}
          contextUuid={ENV.canvas_outcomes.context_uuid}
          artifactType={ENV.canvas_outcomes.artifact_type}
          artifactId={ENV.canvas_outcomes.artifact_id}
        />
      </View>,
      container
    )
  }
})
