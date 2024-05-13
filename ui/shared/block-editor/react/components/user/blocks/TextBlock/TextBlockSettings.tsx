/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useNode} from '@craftjs/core'
import {Slider, FormControl, FormLabel} from '@mui/material'

const TextBlockSettings = () => {
  const {
    actions: {setProp},
    fontSize,
  } = useNode(node => ({
    fontSize: node.data.props.fontSize,
  }))

  return (
    <FormControl>
      <FormLabel component="legend">Font Size</FormLabel>
      <Slider
        value={fontSize || 7}
        step={1}
        min={7}
        max={50}
        valueLabelDisplay="auto"
        onChange={(_, value) => {
          setProp(prps => (prps.fontSize = value))
        }}
      />
    </FormControl>
  )
}

export {TextBlockSettings}
