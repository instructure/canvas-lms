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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import 'compiled/jquery.rails_flash_notifications'

  var FlashMessageHolder = React.createClass({
    displayName: 'FlashMessageHolder',

    propTypes: {
      time: PropTypes.number.isRequired,
      message: PropTypes.string.isRequired,
      error: PropTypes.bool,
      onError: PropTypes.func,
      onSuccess: PropTypes.func
    },

    shouldComponentUpdate (nextProps, nextState) {
      return nextProps.time > this.props.time;
    },

    componentWillUpdate (nextProps, nextState) {
      if (nextProps.error) {
        (nextProps.onError) ?
        nextProps.onError(nextProps.message) :
        $.flashError(nextProps.message);
      } else {
        (nextProps.onSuccess) ?
        nextProps.onSuccess(nextProps.message) :
        $.flashMessage(nextProps.message);
      }
    },

    render () {
      return null;
    }
  });

export default FlashMessageHolder
