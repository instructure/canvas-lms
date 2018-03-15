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

import $ from 'jquery'

  var request = null;

  const FlickrActions = {

    startFlickrSearch(term, page) {
      return { type: 'START_FLICKR_SEARCH', term, page };
    },

    receiveFlickrResults(originalResults) {
      const photos = Object.assign({}, originalResults.photos)
      if (photos.photo) {
        photos.photo = photos.photo.filter(photo => photo.needs_interstitial !== 1)
      }
      const results = Object.assign({}, originalResults, { photos })
      return { type: 'RECEIVE_FLICKR_RESULTS', results }
    },

    clearFlickrSearch() {
      this.cancelFlickrSearch();
      return { type: 'CLEAR_FLICKR_SEARCH' }
    },

    failFlickrSearch(error) {
      return { type: 'FAIL_FLICKR_SEARCH', error };
    },

    cancelFlickrSearch() {
      if (request) {
        request.abort();
      }
    },

    searchFlickr(term, page) {
      return (dispatch) => {
        dispatch(this.startFlickrSearch(term, page));
        this.flickrApiGet(term, page, dispatch);
      }
    },

    flickrApiGet(term, page, dispatch){
      const url = this.composeFlickrUrl(term, page);

      this.cancelFlickrSearch();

      request = $.getJSON(url)
        .done( (results) => {
          dispatch(this.receiveFlickrResults(results));
        })
        .fail( (error) => {
          dispatch(this.failFlickrSearch(error));
        });
    },

    composeFlickrUrl(term, page) {
      // This API key has been in Canvas forever, so no qualms about putting it here.
      // Ideally this key should be rotated and stored securely elsewhere.
      const apiKey = '734839aadcaa224c4e043eaf74391e50';
      const sort = 'relevance';
      const licenses = '9';
      const per_page = '20';
      const imageSize = 'url_m';

      return `https://api.flickr.com/services/rest/?method=flickr.photos.search&format=json&nojsoncallback=true&api_key=${apiKey}&sort=${sort}&license=${licenses}&text=${term}&per_page=${per_page}&content_type=6&safe_search=1&page=${page}&privacy_filter=1&extras=license,owner_name,${imageSize},needs_interstitial`
    }
  };

export default FlickrActions

