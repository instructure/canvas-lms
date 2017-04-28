/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import _ from 'underscore'
  var BaseIcon = React.createClass({
    propTypes: {
      name: React.PropTypes.string.isRequired,
      content: React.PropTypes.string.isRequired,
      viewBox: React.PropTypes.string.isRequired,
      title: React.PropTypes.string,
      desc: React.PropTypes.string,
      width: React.PropTypes.string,
      height: React.PropTypes.string
    },

    componentWillMount () {
      this.titleId = _.uniqueId('iconTitle_');
      this.descId = _.uniqueId('iconDesc_');
    },

    componentDidMount () {
      ReactDOM.findDOMNode(this).setAttribute('focusable', 'false')
    },

    getDefaultProps () {
      return {
        width: '1em',
        height: '1em'
      }
    },

    getRole () {
      if (this.props.title) {
        return 'img'
      } else {
        return 'presentation'
      }
    },

    renderTitle () {
      const { title } = this.props
      return (title) ? (
        <title id={this.titleId}>{title}</title>
      ) : null
    },

    renderDesc () {
      const { desc } = this.props
      return (desc) ? (
        <desc id={this.descId}>{desc}</desc>
      ) : null
    },

    getLabelledBy () {
      const ids = []

      if (this.props.title) {
        ids.push(this.titleId)
      }

      if (this.props.desc) {
        ids.push(this.descId)
      }

      return (ids.length > 0) ? ids.join(' ') : null
    },

    render () {
      const {
        title,
        width,
        height,
        viewBox,
        className
      } = this.props
      const style = {
        fill: 'currentColor'
      }
      return (
        <svg
          style={style}
          width={width}
          height={height}
          viewBox={viewBox}
          aria-hidden={title ? null : 'true'}
          aria-labelledby={this.getLabelledBy()}
          role={this.getRole()}>
          {this.renderTitle()}
          {this.renderDesc()}
          <g role="presentation" dangerouslySetInnerHTML={{__html: this.props.content}} />
        </svg>
      )
    }
  });

export default BaseIcon
