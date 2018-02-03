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

import React from 'react';
import { arrayOf, shape, string } from 'prop-types';
import { statuses } from '../../../gradezilla/default_gradebook/constants/statuses';
import { darken } from '../../../gradezilla/default_gradebook/constants/colors';

function GridColor (props) {
  const styleRules = props.statuses.map(status =>
    [
      `.even .gradebook-cell.${status} { background-color: ${props.colors[status]}; }`,
      `.odd .gradebook-cell.${status} { background-color: ${darken(props.colors[status], 5)}; }`,
      `.slick-cell.editable .gradebook-cell.${status} { background-color: white; }`
    ].join('')
  ).join('');

  return (
    <style type="text/css">
      {styleRules}
    </style>
  );
}

GridColor.propTypes = {
  colors: shape({
    late: string,
    missing: string,
    resubmitted: string,
    dropped: string,
    excused: string
  }).isRequired,
  statuses: arrayOf(string)
};

GridColor.defaultProps = {
  statuses
};

export default GridColor;
