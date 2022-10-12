/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import ColumnHeader from './ColumnHeader'

type Props = {
  title: string
}

export default class CustomColumnHeader extends ColumnHeader<Props, {}> {
  render() {
    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span
          className="Gradebook__ColumnHeaderDetail Gradebook__ColumnHeaderDetail--OneLine"
          style={{textAlign: 'center', width: '100%'}}
        >
          <Text as="span" size="x-small">
            {this.props.title}
          </Text>
        </span>
      </div>
    )
  }
}
