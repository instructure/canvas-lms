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

import React, {useEffect, useState} from 'react'
import classNames from 'classnames'

const useClassNames = (
  enabled: boolean,
  nodeState: {
    empty: boolean
    selected?: boolean
    hovered?: boolean
  },
  others?: string | string[]
) => {
  const {empty, selected = false, hovered = false} = nodeState
  const rest: string[] = others ? (Array.isArray(others) ? others : [others]) : []

  const [classNameState, setClassNameState] = useState<string>('')

  useEffect(() => {
    const newClassNames = classNames({
      ...rest.reduce((prev: Record<string, boolean>, curr: string) => {
        const next = {...prev}
        next[curr] = true
        return next
      }, {}),
      enabled,
      empty: empty && enabled,
      selected,
      hovered,
    })
    setClassNameState(newClassNames)
  }, [empty, hovered, selected, rest, enabled])

  return classNameState
}

export {useClassNames}
