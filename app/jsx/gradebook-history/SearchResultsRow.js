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
import { shape, string } from 'prop-types';

const SearchResultsRow = (props) => {
  const item = props.item;
  return (
    <tr>
      <td>{item.date}</td>
      <td>{item.time}</td>
      <td>{item.from}</td>
      <td>{item.to}</td>
      <td>{item.grader}</td>
      <td>{item.student}</td>
      <td>{item.assignment}</td>
      <td>{item.anonymous}</td>
    </tr>
  );
};

SearchResultsRow.propTypes = {
  item: shape({
    date: string.isRequired,
    time: string.isRequired,
    from: string.isRequired,
    to: string.isRequired,
    grader: string.isRequired,
    student: string.isRequired,
    assignment: string.isRequired,
    anonymous: string.isRequired
  }).isRequired
};

export default SearchResultsRow;
