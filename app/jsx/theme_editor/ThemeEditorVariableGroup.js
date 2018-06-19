/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ToggleDetails from '@instructure/ui-core/lib/components/ToggleDetails'
import {bool, func, node, number} from 'prop-types'
import IconArrowOpenUpSolid from 'instructure-icons/lib/Solid/IconArrowOpenUpSolid'

export default function ThemeEditorVariableGroup(props) {
  function handleToggle(event, expanded) {
    props.onToggle(event, expanded, props.index)
  }

  return (
    <ToggleDetails
      summary={props.summary}
      expanded={props.expanded}
      onToggle={handleToggle}
      icon={IconArrowOpenUpSolid}
      iconPosition="end"
      fluidWidth
    >
      {props.children}
    </ToggleDetails>
  )
}

ThemeEditorVariableGroup.propTypes = {
  summary: node.isRequired,
  expanded: bool,
  children: node.isRequired,
  onToggle: func.isRequired,
  index: number.isRequired
}

ThemeEditorVariableGroup.defaultProps = {
  expanded: false
}
