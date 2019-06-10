/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {arrayOf} from 'prop-types'
import axios from 'axios'
import LoadingIndicator from '../../assignments_2/shared/LoadingIndicator'
import {MediaObjectShape} from './props'
import React from 'react'
import {VideoPlayer} from '@instructure/ui-media-player'


export default class CanvasMediaPlayer extends React.Component {
  static propTypes = {
    mediaSources: arrayOf(MediaObjectShape)
  }

  state = {
    mediaSources: this.props.mediaSources
  }

  componentDidMount () {
    const frames = window.parent.document.getElementsByTagName("iframe")
    let containingIframe = null
    for (let index = 0; index < frames.length; ++index) {
      containingIframe = frames[index]
      // eslint-disable-next-line eqeqeq
      if (containingIframe.contentWindow == window) {
        containingIframe.frameBorder = "none";
        break
      }
    }
    if (!this.props.mediaSources.length) {
      this.pollInfo()
    }
  }

  componentWillUnmount () {
    clearTimeout(this.pollTimeout)
  }

  async pollInfo () {
    const pathSplit = window.location.pathname.split('/')
    const mediaObjectId = pathSplit[pathSplit.length-1]
    const mediaObjectInfo = await this.fetchMediaObjectInfo(mediaObjectId)
    if (mediaObjectInfo.data.media_sources.length) {
      this.setState({ mediaSources: mediaObjectInfo.data.media_sources})
    } else {
      this.pollTimeout = setTimeout(() => this.pollInfo(), 1000)
    }
  }

  async fetchMediaObjectInfo (mediaObjectId) {
    const data = await axios.get(`${window.location.origin}/media_objects/${mediaObjectId}/info`)
    return data
  }

  render() {
    return (
      <div>
        {this.state.mediaSources.length ?
            <VideoPlayer sources={this.state.mediaSources} /> : <LoadingIndicator />
        }
      </div>
    )
  }
}
