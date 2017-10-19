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
import PropTypes from 'prop-types'
import _ from 'underscore'
import classnames from 'classnames'

const { string, any, bool } = PropTypes
let idCount = 0
const IcInputPropTypes = {
  error: string,
  label: string,
  hint: string,
  elementType: any,
  controlClassName: string,
  appendLabel: bool,
  noClassName: bool,
  type: string
}

  /**
   * An input wrapped with appropriate ic-Form-* elements and classes,
   * with support for a label, error message and extra classes on the
   * wrapping div.
   *
   * All other props are passed through to the <input />
   */
  class IcInput extends React.Component {
    static propTypes = IcInputPropTypes
    static defaultProps = {
      elementType: 'input'
    }

    componentWillMount () {
      this.id = `ic_input_${idCount++}`;
    }

    render () {
      const { error, label, hint, elementType, appendLabel, controlClassName, noClassName } = this.props
      const inputProps = Object.assign({}, _.omit(this.props, Object.keys(IcInputPropTypes)), {id: this.id})
      if (elementType === "input" && !this.props.type) {
        inputProps.type = "text";
      }
      if (this.props.type) {
        inputProps.type = this.props.type
      }
      if (!noClassName) {
        inputProps.className = classnames(inputProps.className, "ic-Input");
      }

      const labelElement = label &&
        <label htmlFor={this.id} className="ic-Label">{label}</label>;

      const hintElement = !!hint && <div className="ic-Form-help-text">{hint}</div>

      return (
        <div className={classnames('ic-Form-control', controlClassName, {'ic-Form-control--has-error': error})}>
          {!!label && !appendLabel && labelElement}
          {React.createElement(elementType, inputProps)}
          {!!label && appendLabel && labelElement}
          {!!error &&
            <div className="ic-Form-message ic-Form-message--error">
              <div className="ic-Form-message__Layout">
                <i className="icon-warning" role="presentation" />
                {error}
              </div>
            </div>
          }
          {!!hint && hintElement}
        </div>
      );
    }
  }

export default IcInput
