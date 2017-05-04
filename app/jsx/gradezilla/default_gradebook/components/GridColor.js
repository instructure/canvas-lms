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
import { getUserColors } from 'jsx/gradezilla/default_gradebook/stores/UserColorStore';

function GridColor (props) {
  const colorsByState = getUserColors(props.colors);
  const styleRules = props.states.map(state =>
    [
      `.even .gradebook-cell.${state} { background-color: ${colorsByState.light[state]}; }`,
      `.odd .gradebook-cell.${state} { background-color: ${colorsByState.dark[state]}; }`,
      `.slick-cell.editable .gradebook-cell.${state} { background-color: white; }`
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
  states: arrayOf(string)
};

GridColor.defaultProps = {
  states: ['late', 'missing', 'resubmitted', 'dropped', 'excused']
};

export default GridColor;
