#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'Backbone'
  'jquery'
  'compiled/views/FindFlickrImageView'
  'helpers/jquery.simulate'
], (Backbone, $, FindFlickrImageView) ->

  searchTerm = 'bunnies'
  photoData = [
    {id: "noooooo", secret: "whyyyyy", farm: "moooo", owner: "notyou", server: "maneframe"}
    {id: "nooope", secret: "sobbbbb", farm: "sadface", owner: "meeee", server: "mwhahahah"}
  ]

  setupServerResponses = ->
    server = sinon.fakeServer.create()
    server.respondWith /\/mock_flickr\/(.*)/, (request) ->
      response = {
        photos: {
         photo: photoData
        }
      }
      if request.url.indexOf(searchTerm) != -1
        request.respond 200,
          'Content-Type': 'application/json'
          JSON.stringify response

    server

  module 'FindFlickrImage',
    setup: ->
      @server = setupServerResponses()

      $fixtures = $('#fixtures')

      view = new FindFlickrImageView
      view.flickrUrl = '/mock_flickr'
      view.render().$el.appendTo($fixtures)
      @form = $('form.FindFlickrImageView').first()

    teardown: ->
      @form.remove()
      @server.restore()

  test 'render', ->
    expect 6

    ok @form.length, 'flickr - form added to dom'
    ok @form.is(':visible'), 'flickr - form is visible'

    input = $('input.flickrSearchTerm', @form)
    ok input.length, 'flickr - search bar is added'
    ok input.is(':visible'), 'flickr - search bar is visible'

    button = $('button[type=submit]', @form)
    ok button.length, 'flickr - submit button is added'
    ok button.is(':visible'), 'flickr - submit button form is visible'

  test 'search', ->
    expect 13

    input = $('input.flickrSearchTerm', @form)
    button = $('button[type=submit]', @form)

    input.val(searchTerm)
    @form.submit()
    # $('button[type=submit]', @form).simulate 'click'
    @server.respond()

    results = $('ul.flickrResults li a.thumbnail', @form)
    equal results.length, 2, 'images are added to the results'

    for idx in [0..1]
      ok results.eq(idx).attr('data-fullsize').indexOf(photoData[idx].id) != -1, 'flickr - img src has id'
      ok results.eq(idx).attr('data-fullsize').indexOf(photoData[idx].secret) != -1, 'flickr - img src has secret'
      ok results.eq(idx).attr('data-fullsize').indexOf(photoData[idx].farm) != -1, 'flickr - img src has farm'
      ok results.eq(idx).attr('data-fullsize').indexOf(photoData[idx].server) != -1, 'flickr - img src has server'
      ok results.eq(idx).attr('data-linkto').indexOf(photoData[idx].id) != -1, 'flickr - link has id'
      ok results.eq(idx).attr('data-linkto').indexOf(photoData[idx].owner) != -1, 'flickr - link has owner'
