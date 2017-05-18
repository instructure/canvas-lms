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
  let main = document.querySelector('#main')

  class CollaborationsToolLaunch extends React.Component {
    constructor (props) {
      super(props)
      this.state = {height: 500}

      this.setHeight = this.setHeight.bind(this)
    }

    componentDidMount () {
      this.setHeight()
      window.addEventListener('resize', this.setHeight)
    }

    componentWillUnMount () {
      window.removeEventListener('resize', this.setHeight)
    }

    setHeight () {
      this.setState({
        height: main.getBoundingClientRect().height - 48
      })
    }

    render () {
      return (
        <div className='CollaborationsToolLaunch' style={{height: this.state.height}}>
          <iframe
            className='tool_launch'
            src={this.props.launchUrl}
          ></iframe>
        </div>
      )
    }
  }

export default CollaborationsToolLaunch
