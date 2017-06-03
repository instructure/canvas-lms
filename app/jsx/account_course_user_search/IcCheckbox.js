/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import IcInput from './IcInput'
import classnames from 'classnames'

  var { string } = React.PropTypes;

  /**
   * A checkbox input wrapped with appropriate ic-Form-* elements and
   * classes, with support for a label and error message.
   *
   * All other props are passed through to the
   * <input />
   */
  var IcCheckbox = React.createClass({
    propTypes: {
      error: string,
      label: string
    },

    render() {
      var { controlClassName } = this.props;

      return (
        <IcInput
          {...this.props}
          type="checkbox"
          appendLabel={true}
          noClassName={true}
          controlClassName={classnames("ic-Form-control--checkbox", controlClassName)}
        />
      );
    }
  });
export default IcCheckbox
