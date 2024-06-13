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

import React, {useCallback} from 'react'
import {useNode} from '@craftjs/core'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'

const HeadingBlockSettings = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))

  const handleLevelChange = useCallback(
    (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setProp(prps => (prps.level = value))
    },
    [setProp]
  )

  return (
    <RadioInputGroup
      description="Select level"
      onChange={handleLevelChange}
      name="level"
      size="small"
      value={props.level}
    >
      <RadioInput value="h2" label="Heading 2" />
      <RadioInput value="h3" label="Heading 3" />
      <RadioInput value="h4" label="Heading 4" />
    </RadioInputGroup>
  )
}

export {HeadingBlockSettings}
