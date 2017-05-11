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
  var IconInformation = React.createClass({
    render () {
      const content = `
        <path d="M100 200C44.9 200 0 155.1 0 100 0 44.9 44.9 0 100 0s100 44.9 100 100C200 155.1 155.1 200 100
          200zM100 20c-44.1 0-80 35.9-80 80s35.9 80 80 80 80-35.9 80-80S144.1 20 100 20z"/>
          <path d="M110 130V90c0-5.5-4.5-10-10-10H80v20h10v30H70v20h60v-20H110z"/>
          <circle cx="100" cy="60" r="12.5"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconInformation"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

export default IconInformation
