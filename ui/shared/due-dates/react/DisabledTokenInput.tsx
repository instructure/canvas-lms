/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {map} from 'es-toolkit/compat'

interface DisabledTokenInputProps {
  tokens?: string[]
}

const styles = {
  list: {
    backgroundColor: '#eeeeee',
  },
  label: {
    backgroundColor: 'white',
    borderRadius: '3px',
  },
} as const

const DisabledTokenInput: React.FC<DisabledTokenInputProps> = ({tokens}) => {
  const renderTokens = () => {
    return map(tokens, (token, index) => (
      <li key={`token-${index}`} className="ic-token inline-flex">
        <span className="ic-token-label" style={styles.label}>
          {token}
        </span>
      </li>
    ))
  }

  return (
    <ul
      // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
      tabIndex={0}
      aria-labelledby="assign-to-label"
      className="ic-tokens flex"
      style={styles.list}
    >
      {renderTokens()}
    </ul>
  )
}

export default DisabledTokenInput
