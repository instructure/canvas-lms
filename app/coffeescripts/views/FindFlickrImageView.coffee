#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'jquery'
  'underscore'
  'str/htmlEscape'
  'jst/FindFlickrImageView'
  'jst/FindFlickrImageResult'
], (Backbone, $, _, h, template, resultTemplate) ->

  class FindFlickrImageView extends Backbone.View

    tagName: 'form'

    attributes:
      'class': 'bootstrap-form form-horizontal FindFlickrImageView'

    template: template

    events:
      'submit' : 'searchFlickr'
      'change .flickrSearchTerm' : 'hideResultsIfEmptySearch'
      'input .flickrSearchTerm' : 'hideResultsIfEmptySearch'
      
    hideResultsIfEmptySearch: ->
      @renderResults([]) unless @$('.flickrSearchTerm').val()

    searchFlickr: (event) ->
      event?.preventDefault()
      return unless query = @$('.flickrSearchTerm').val()

      flickrUrl = "#{@flickrUrl}/#{query}" if @flickrUrl
      flickrUrl ||= 'https://api.flickr.com/services/rest/?method=flickr.photos.search&format=json' +
                  '&api_key=734839aadcaa224c4e043eaf74391e50&sort=relevance&license=1,2,3,4,5,6' +
                  "&text=#{query}&per_page=150&extras=needs_interstitial&jsoncallback=?"
      @request?.abort()
      @$('.flickrResults').show().disableWhileLoading @request = $.getJSON flickrUrl, (data) =>
        photos = data.photos.photo
        @renderResults(photos)

    renderResults: (photos) ->
      html = _.reject(photos, (photo) => photo.needs_interstitial == 1)
        .map((photo) ->
          resultTemplate
            thumb:    "https://farm#{photo.farm}.static.flickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_s.jpg"
            fullsize: "https://farm#{photo.farm}.static.flickr.com/#{photo.server}/#{photo.id}_#{photo.secret}.jpg"
            source:   "https://secure.flickr.com/photos/#{photo.owner}/#{photo.id}"
            title:    photo.title
        )
      html = html.join('')

      @$('.flickrResults').showIf(!!photos.length).html html
