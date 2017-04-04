/*
 * Copyright (C) 2017 Instructure, Inc.
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
import Typography from 'instructure-ui/lib/components/Typography'

const { string } = React.PropTypes;

function CustomColumnHeader (props) {
  return (
    <div className="Gradebook__ColumnHeaderContent">
      <span className="Gradebook__ColumnHeaderDetail">
        <Typography tag="span" size="small">
          { props.title }
        </Typography>
      </span>
    </div>
  );
}

CustomColumnHeader.propTypes = {
  title: string.isRequired
};

export default CustomColumnHeader
