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

import $ from 'jquery'
import ExternalFeedCollection from 'compiled/collections/ExternalFeedCollection'
import ExternalFeed from 'compiled/models/ExternalFeed'
import ExternalFeedsIndexView from 'compiled/views/ExternalFeeds/IndexView'
import fakeENV from 'helpers/fakeENV'

QUnit.module('IndexView', {
  setup() {
    fakeENV.setup({context_asset_string: 'courses_1'})
    $('#fixtures').append($('<div>').attr('id', 'feed_container'))
    const ef = new ExternalFeed({
      id: 1,
      url: 'http://www.example.com/feed',
      display_name: 'Example Feed',
      verbosity: 'link_only',
      header_match: null
    })
    const efc = new ExternalFeedCollection([ef])
    this.view = new ExternalFeedsIndexView({
      el: '#feed_container',
      permissions: {create: true},
      collection: efc
    })
    return this.view.render()
  },
  teardown() {
    this.view.remove()
    $('#fixtures').empty()
    fakeENV.teardown()
  }
})
const submitForm = function(url) {
  $('.add_external_feed_link').click()
  $('#external_feed_url').val(url)
  $('#external_feed_verbosity').val('link_only')
  return $('#add_external_feed_form button').click()
}
test('renders the list of feeds', () => {
  equal($('li.external_feed').length, 1)
  ok(
    $('li.external_feed')
      .text()
      .match('Example Feed')
  )
})

test('validates the url properly', function() {
  let errors = this.view.validateBeforeSave({url: ''})
  equal(errors.url.length, 1)
  errors = this.view.validateBeforeSave({url: 'http://example.com'})
  ok(!errors.url)
})
