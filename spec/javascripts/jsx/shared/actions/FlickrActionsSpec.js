/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import FlickrActions from 'jsx/shared/actions/FlickrActions'

QUnit.module('Flickr Actions')

test('receiveFlickrResults removes images with needs_interstitial=1', () => {
  const results = {
    photos: {
      photo: [
        { id: 1, needs_interstitial: 0 },
        { id: 2, needs_interstitial: 1 },
        { id: 3, needs_interstitial: 0 }
      ]
    }
  }
  const action = FlickrActions.receiveFlickrResults(results)
  deepEqual(action, {
    type: 'RECEIVE_FLICKR_RESULTS',
    results: {
      photos: {
        photo: [
          { id: 1, needs_interstitial: 0 },
          { id: 3, needs_interstitial: 0 }
        ]
      }
    }
  })
})

test('composeFlickrUrl includes needs_interstitial in extras', () => {
  const url = new URL(FlickrActions.composeFlickrUrl('fake', 1))
  notEqual(url.searchParams.get('extras').split(',').indexOf('needs_interstitial'), -1)
})
