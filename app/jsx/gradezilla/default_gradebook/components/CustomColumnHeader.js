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
import Typography from 'instructure-ui/lib/components/Typography'
import ColumnHeader from 'jsx/gradezilla/default_gradebook/components/ColumnHeader'

const { string } = PropTypes;

class CustomColumnHeader extends ColumnHeader {
  render () {
    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <Typography tag="span" size="small">
            { this.props.title }
          </Typography>
        </span>
      </div>
    );
  }
}

CustomColumnHeader.propTypes = {
  title: string.isRequired
};

export default CustomColumnHeader
