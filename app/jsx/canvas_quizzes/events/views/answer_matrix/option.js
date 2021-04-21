/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

const Option = ({checked, label, name, onChange}) => {
  return (
    // it's a fluke since we are passing children for the label
    // eslint-disable-next-line jsx-a11y/label-has-associated-control
    <label>
      <input
        data-testid="checkbox"
        type="checkbox"
        onChange={e => onChange(name, e.target.checked)}
        checked={checked}
      />

      {label}
    </label>
  )
}

export default Option
