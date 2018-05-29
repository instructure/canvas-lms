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
import PropTypes from 'prop-types'
import Text from '@instructure/ui-elements/lib/components/Text'
import ColumnHeader from './ColumnHeader'

const { string } = PropTypes;

export default class CustomColumnHeader extends ColumnHeader {
  static propTypes = {
    title: string.isRequired
  };

  render () {
    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail" style={{ textAlign: 'center', width: '100%' }}>
          <Text tag="span" size="x-small">
            { this.props.title }
          </Text>
        </span>
      </div>
    );
  }
}
