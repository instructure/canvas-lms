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
import BaseIcon from './BaseIcon'
  var IconFolder = React.createClass({
    render () {
      const content = `
        <path d="M180 45H97.5L81 23c-3.8-5-9.7-8-16-8H20C9 15 0 24 0 35v130c0 11 9 20 20 20h160c11 0 20-9
          20-20V65C200 54 191 45 180 45zM20 165V35h45l16.5 22c3.8 5 9.7 8 16 8H180l0 100H20z"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconFolder"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

export default IconFolder
