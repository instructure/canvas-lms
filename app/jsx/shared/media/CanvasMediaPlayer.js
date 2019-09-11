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
import {string} from 'prop-types'
import LoadingIndicator from '../../assignments_2/shared/LoadingIndicator'
import React from 'react'
import {VideoPlayer} from '@instructure/ui-media-player'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'

export default class CanvasMediaPlayer extends React.Component {
  static propTypes = {
    media_id: string.isRequired,
    media_sources: VideoPlayer.propTypes.sources
  }

  static defaultProps = {
    media_sources: []
  }

  state = {media_sources: []}

  componentDidMount() {
    if (!this.props.media_sources.length) this.fetchSources()

    const iframeEl = [...window.parent.document.getElementsByTagName('iframe')].find(
      el => el.contentWindow === window
    )
    if (iframeEl) iframeEl.frameBorder = 'none'
  }

  async fetchSources() {
    const url = `/media_objects/${this.props.media_id}/info`
    let resp
    try {
      resp = await asJson(fetch(url, defaultFetchOptions))
    } catch (e) {
      // if there is a network error, just ignore and retry
    }
    if (resp && resp.media_sources && resp.media_sources.length) {
      this.setState({media_sources: resp.media_sources})
    } else {
      // if they're not present yet, try again in a little bit
      await new Promise(resolve => setTimeout(resolve, 1000))
      await this.fetchSources()
    }
  }

  render() {
    const sources = this.props.media_sources.length ? this.props.media_sources : this.state.media_sources
    return (
      <div>
        {sources.length ? <VideoPlayer sources={sources} /> : <LoadingIndicator />}
      </div>
    )
  }
}
