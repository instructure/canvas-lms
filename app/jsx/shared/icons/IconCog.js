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
  var IconCog = React.createClass({
    render () {
      const content = `
        <path d="M200 120V80h-22.6c-2.3-9-6.1-17.4-11.2-24.9l15.2-15.2 -21.2-21.2
            -15.2 15.2C137.4 28.8 129 25 120 22.6V0H80v22.6c-9 2.3-17.4 6.1-24.9 11.2L39.9
            18.7 18.7 39.9l15.2 15.2C28.8 62.6 25 71 22.6 80H0v40h22.6c2.3 9 6.1 17.4 11.2 24.9l-15.2
            15.2 21.2 21.2 15.2-15.2c7.5 5.1 15.9 8.9 24.9 11.2V200h40v-22.6c9-2.3 17.4-6.1 24.9-11.2l15.2
            15.2 21.2-21.2 -15.2-15.2c5.1-7.5 8.9-15.9 11.2-24.9H200zM100 160c-33.1 0-60-26.9-60-60 0-33.1
            26.9-60 60-60s60 26.9 60 60C160 133.1 133.1 160 100 160z"/>
      `;
      return (
        <BaseIcon
          {...this.props}
          name="IconCog"
          viewBox="0 0 200 200" content={content} />
      )
    }
  });

export default IconCog
