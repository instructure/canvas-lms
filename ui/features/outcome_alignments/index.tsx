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
import {legacyRender} from '@canvas/react'
import {View} from '@instructure/ui-view'
import ready from '@instructure/ready'

// @ts-expect-error - local workspace lacks module declarations for outcomes-ui
import {AlignmentWidget} from '@instructure/outcomes-ui'

type CanvasOutcomesConfig = {
  host: string
  jwt: string
  context_uuid: string
  artifact_type: string
  artifact_id: string | number
}

ready(() => {
  const container = document.querySelector<HTMLElement>('#canvas_outcomes_alignment_widget')
  // @ts-expect-error - page-specific ENV property for outcomes alignment widget
  const canvasOutcomes: CanvasOutcomesConfig | undefined = ENV.canvas_outcomes

  if (container && canvasOutcomes?.host) {
    legacyRender(
      <View as="div" borderWidth="small none none none" padding="medium none">
        <AlignmentWidget
          host={canvasOutcomes.host}
          jwt={canvasOutcomes.jwt}
          contextUuid={canvasOutcomes.context_uuid}
          artifactType={canvasOutcomes.artifact_type}
          artifactId={canvasOutcomes.artifact_id}
        />
      </View>,
      container,
    )
  }
})
