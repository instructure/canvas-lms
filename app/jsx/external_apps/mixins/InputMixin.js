/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import React from 'react'
import classMunger from '../../external_apps/lib/classMunger'

export default {
    getInitialState() {
      return {
        value: this.props.defaultValue
      }
    },

    handleChange(e) {
      e.preventDefault();
      this.setState({ value: e.target.value });
    },

    handleCheckChange(e) {
      this.setState({ value: !!e.target.checked })
    },

    renderHint() {
      var hintText = this.props.hintText;
      if (!!this.getErrorMessage()) {
        hintText = this.getErrorMessage();
      }
      return hintText ? <span ref="hintText" className="hint-text">{hintText}</span> : null;
    },

    getClassNames() {
      return classMunger('control-group', {'error': this.props.id in this.props.errors});
    },

    getErrorMessage() {
      return this.props.errors[this.props.id];
    }
  }
