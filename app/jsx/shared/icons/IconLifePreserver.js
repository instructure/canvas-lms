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
  var IconLifePreserver = React.createClass({
    render () {
      const content = `
        <path d="M190 80h-2.3C180 46.4 153.6 20 120 12.3V10c0-5.5-4.5-10-10-10H90c-5.5 0-10 4.5-10 10v2.3C46.4
          20 20 46.4 12.3 80H10C4.5 80 0 84.5 0 90v20c0 5.5 4.5 10 10 10h2.3c7.7 33.6 34.1 60 67.7 67.7v2.3c0
          5.5 4.5 10 10 10h20c5.5 0 10-4.5 10-10v-2.3c33.6-7.7 60-34.1 67.7-67.7h2.3c5.5 0 10-4.5 10-10V90C200
          84.5 195.5 80 190 80zM167.1 80h-32.6c-3.5-6-8.4-10.9-14.4-14.4V32.9C142.5 39.7 160.3 57.5 167.1 80zM100
          120c-11 0-20-9-20-20s9-20 20-20c11 0 20 9 20 20S111 120 100 120zM80 32.9v32.6C74 69.1 69.1 74 65.6
          80H32.9C39.7 57.5 57.5 39.7 80 32.9zM32.9 120h32.6c3.5 6 8.4 10.9 14.4 14.4v32.6C57.5 160.3 39.7 142.5
          32.9 120zM120 167.1v-32.6c6-3.5 10.9-8.4 14.4-14.4h32.6C160.3 142.5 142.5 160.3 120 167.1z"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconLifePreserver"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

export default IconLifePreserver
