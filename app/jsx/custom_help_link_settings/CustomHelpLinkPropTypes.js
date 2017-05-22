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

export default {
    link: React.PropTypes.shape({
      text: React.PropTypes.string.isRequired,
      url: React.PropTypes.string.isRequired,
      subtext: React.PropTypes.string,
      available_to: React.PropTypes.array,
      type: React.PropTypes.oneOf(['default', 'custom']),
      id: React.PropTypes.string,

      index: React.PropTypes.number,
      state: React.PropTypes.oneOf(['new', 'active', 'deleted']),
      action: React.PropTypes.oneOf(['edit', 'focus']),
      is_disabled: React.PropTypes.bool
    })
  }
