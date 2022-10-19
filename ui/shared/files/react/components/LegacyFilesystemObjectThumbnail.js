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

import BackboneMixin from '../mixins/BackboneMixin'
import Folder from '../../backbone/models/Folder'
import customPropTypes from '../modules/customPropTypes'

export default {
  displayName: 'FilesystemObjectThumbnail',

  propTypes: {
    model: customPropTypes.filesystemObject,
  },

  mixins: [BackboneMixin('model')],

  getInitialState() {
    return {
      thumbnail_url: this.props.model && this.props.model.get('thumbnail_url'),
    }
  },

  componentDidMount() {
    // Set an interval to check for thumbnails
    // if they don't currently exist (e.g. when
    // a thumbnail is being generated but not
    // immediately available after file upload)
    const intervalMultiplier = 2.0
    let delay = 10000
    let attempts = 0
    const maxAttempts = 4

    const checkThumbnailTimeout = () => {
      delay *= intervalMultiplier
      attempts++

      return setTimeout(() => {
        this.checkForThumbnail(checkThumbnailTimeout)
        if (attempts >= maxAttempts) return clearTimeout(checkThumbnailTimeout)
        checkThumbnailTimeout()
      }, delay)
    }

    checkThumbnailTimeout()
  },

  checkForThumbnail(timeout) {
    if (
      this.state.thumbnail_url ||
      (this.props.model &&
        this.props.model.attributes &&
        this.props.model.attributes.locked_for_user) ||
      this.props.model instanceof Folder ||
      (this.props.model &&
        this.props.model.get('content-type') &&
        this.props.model.get('content-type').match('audio'))
    ) {
      return
    }

    if (this.props.model)
      return this.props.model.fetch({
        success: (model, response, _options) =>
          setTimeout(() => {
            if (response && response.thumbnail_url) {
              this.setState({thumbnail_url: response.thumbnail_url})
            }
          }, 0),
        error() {
          return clearTimeout(timeout)
        },
      })
  },
}
