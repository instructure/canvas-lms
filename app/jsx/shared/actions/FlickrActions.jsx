define ([
  'jquery'
], ($) => {

  var request = null;

  const FlickrActions = {

    startFlickrSearch(term, page) {
      return { type: 'START_FLICKR_SEARCH', term, page };
    },

    receiveFlickrResults(results) {
      return { type: 'RECEIVE_FLICKR_RESULTS', results };
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
      const licenses = '1,2,3,4,5,6';
      const per_page = '20';
      const imageSize = 'url_m';
    
      return `https://secure.flickr.com/services/rest/?method=flickr.photos.search&format=json&nojsoncallback=true&api_key=${apiKey}&sort=${sort}&license=${licenses}&text=${term}&per_page=${per_page}&content_type=6&safe_search=1&page=${page}&privacy_filter=1&extras=license,owner_name,${imageSize}`
    }
  };

  return FlickrActions;
});