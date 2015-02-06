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
      flickrUrl ||= 'https://secure.flickr.com/services/rest/?method=flickr.photos.search&format=json' +
                  '&api_key=734839aadcaa224c4e043eaf74391e50&sort=relevance&license=1,2,3,4,5,6' +
                  "&text=#{query}&per_page=150&jsoncallback=?"
      @request?.abort()
      @$('.flickrResults').show().disableWhileLoading @request = $.getJSON flickrUrl, (data) =>
        photos = data.photos.photo
        @renderResults(photos)

    renderResults: (photos) ->
      html = _.map photos, (photo) ->
        resultTemplate
          thumb:    "https://farm#{photo.farm}.static.flickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_s.jpg"
          fullsize: "https://farm#{photo.farm}.static.flickr.com/#{photo.server}/#{photo.id}_#{photo.secret}.jpg"
          source:   "https://secure.flickr.com/photos/#{photo.owner}/#{photo.id}"
          title:    photo.title
      html = html.join('')

      @$('.flickrResults').showIf(!!photos.length).html html
