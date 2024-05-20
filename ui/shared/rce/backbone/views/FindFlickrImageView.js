/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {reject} from 'lodash'
import template from '../../jst/FindFlickrImageView.handlebars'
import resultTemplate from '../../jst/FindFlickrImageResult.handlebars'

extend(FindFlickrImageView, Backbone.View)

function FindFlickrImageView() {
  return FindFlickrImageView.__super__.constructor.apply(this, arguments)
}

FindFlickrImageView.prototype.tagName = 'form'

FindFlickrImageView.prototype.attributes = {
  class: 'bootstrap-form form-horizontal FindFlickrImageView',
}

FindFlickrImageView.prototype.template = template

FindFlickrImageView.prototype.events = {
  submit: 'searchFlickr',
  'change .flickrSearchTerm': 'hideResultsIfEmptySearch',
  'input .flickrSearchTerm': 'hideResultsIfEmptySearch',
}

FindFlickrImageView.prototype.hideResultsIfEmptySearch = function () {
  if (!this.$('.flickrSearchTerm').val()) {
    return this.renderResults([])
  }
}

FindFlickrImageView.prototype.searchFlickr = function (event) {
  let flickrUrl, query, ref
  if (event != null) {
    event.preventDefault()
  }
  if (!(query = this.$('.flickrSearchTerm').val())) {
    return
  }
  if (this.flickrUrl) {
    flickrUrl = this.flickrUrl + '/' + query
  }
  flickrUrl ||
    (flickrUrl =
      'https://api.flickr.com/services/rest/?method=flickr.photos.search&format=json' +
      '&api_key=734839aadcaa224c4e043eaf74391e50&sort=relevance&license=1,2,3,4,5,6' +
      ('&text=' + query + '&per_page=150&extras=needs_interstitial&jsoncallback=?'))
  if ((ref = this.request) != null) {
    ref.abort()
  }
  return this.$('.flickrResults')
    .show()
    .disableWhileLoading(
      (this.request = $.getJSON(
        flickrUrl,
        (function (_this) {
          return function (data) {
            const photos = data.photos.photo
            return _this.renderResults(photos)
          }
        })(this)
      ))
    )
}

FindFlickrImageView.prototype.renderResults = function (photos) {
  let html = reject(
    photos,
    (function (_this) {
      return function (photo) {
        return photo.needs_interstitial === 1
      }
    })(this)
  ).map(function (photo) {
    return resultTemplate({
      thumb:
        'https://farm' +
        photo.farm +
        '.static.flickr.com/' +
        photo.server +
        '/' +
        photo.id +
        '_' +
        photo.secret +
        '_s.jpg',
      fullsize:
        'https://farm' +
        photo.farm +
        '.static.flickr.com/' +
        photo.server +
        '/' +
        photo.id +
        '_' +
        photo.secret +
        '.jpg',
      source: 'https://secure.flickr.com/photos/' + photo.owner + '/' + photo.id,
      title: photo.title,
    })
  })
  html = html.join('')
  return this.$('.flickrResults').showIf(!!photos.length).html(html)
}

export default FindFlickrImageView
