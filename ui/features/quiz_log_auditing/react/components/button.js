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
import classSet from '@canvas/quiz-legacy-client-apps/util/class_set'

/**
 * @class Events.Components.Button
 *
 * A wrapper for `<button type="button" />` that abstracts the bootstrap CSS
 * classes we need to specify for buttons.
 */
const Button = ({children, onClick, type = 'default'}) => {
  const className = {}

  className.btn = true
  className['btn-default'] = type === 'default'
  className['btn-danger'] = type === 'danger'
  className['btn-success'] = type === 'success'

  return (
    <button
      data-testid="button"
      onClick={onClick}
      type="button"
      className={classSet(className)}
    >
      {children}
    </button>
  )
}

export default Button
