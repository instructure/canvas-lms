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

import PropTypes from 'prop-types';
import React from 'react';
import Select from '@instructure/ui-core/lib/components/Select';

export default function SelectMenu (props) {
  const options = props.options.map((option) => {
    const text = option[props.textAttribute];
    const value = option[props.valueAttribute];
    return(
      <option key={value} value={value}>
        {text}
      </option>
    );
  });

  return (
    <Select
      defaultValue={props.defaultValue}
      disabled={props.disabled}
      id={props.id}
      inline
      label={props.label}
      onChange={props.onChange}
      width="15rem"
    >
      {options}
    </Select>
  );
}

SelectMenu.propTypes = {
  defaultValue: PropTypes.string.isRequired,
  disabled: PropTypes.bool.isRequired,
  id: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  options: PropTypes.arrayOf(PropTypes.oneOfType([PropTypes.array, PropTypes.object])).isRequired,
  textAttribute: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  valueAttribute: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired
};
