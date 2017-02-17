define([
  'react',
  'react-addons-test-utils',
  'jsx/shared/FlickrSearch'
], (React, TestUtils, FlickrSearch) => {

  QUnit.module('FlickrSearch View');

  var getDummySearchResults = (pageCount) => {
    var photo = [{
      id: 1,
      url_m: "url1"
    },
    {
      id: 2,
      url_m: "url2"
    },
    {
      id: 3,
      url_m: "url3"
    }];

    var photos = {
      pages: pageCount,
      photo: photo
    };

    return {photos: photos};
  }

  test('it renders', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );
    ok(flickrSearch);
  });

  test('it searches flickr on input change', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );
    let called = false;
    flickrSearch.searchFlickr = () => called = true;

    var flickrInput = TestUtils.findRenderedDOMComponentWithClass(flickrSearch, "ic-Input");
    flickrInput.value = "foos";

    const fakeInputEvent = {
      target: flickrInput,
      preventDefault: () => {}
    };

    flickrSearch.handleInput(fakeInputEvent);

    ok(called, 'searchFlickr was called');
  });

  test('it clears flickr results when input is cleared', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );
    let called = false;
    flickrSearch.clearFlickrResults = () => called = true;
    flickrSearch.searchFlickr = () => {return}; //stub out so as not to hit actual flickr api

    var flickrInput = TestUtils.findRenderedDOMComponentWithClass(flickrSearch, "ic-Input");
    flickrInput.value = "";

    const fakeInputEvent = {
      target: flickrInput,
      preventDefault: () => {}
    };

    flickrSearch.handleInput(fakeInputEvent);

    ok(called, 'clearFlickrResults was called');
  });

  asyncTest('it does not render next or previous page buttons when there is only one page of results', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );

    var searchResults = getDummySearchResults(1);

    flickrSearch.setState({searchResults: searchResults}, () => {
      ok(!flickrSearch.refs.flickrSearchControlNext && !flickrSearch.refs.flickrSearchControlPrev, 
       'next and previous did not appear');
      start();
    });
  });

  asyncTest('it only renders next when there is more than one page of results and it is not on the last page', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );

    var searchResults = getDummySearchResults(2);

    flickrSearch.setState({searchResults: searchResults}, () => {
      ok(flickrSearch.refs.flickrSearchControlNext && !flickrSearch.refs.flickrSearchControlPrev, 
       'only next button appeared');
      start();
    });
  });

  asyncTest('it only renders previous when there is more than one page of results and it is not on the first page', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );

    var searchResults = getDummySearchResults(2);

    flickrSearch.setState({page: 2, searchResults: searchResults}, () => {
      ok(!flickrSearch.refs.flickrSearchControlNext && flickrSearch.refs.flickrSearchControlPrev, 
       'only previous button appeared');
      start();
    });
  });

  asyncTest('it renders next and previous when there is more than one page of results and it is on a page inbetween', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );

    var searchResults = getDummySearchResults(3);

    flickrSearch.setState({page: 2, searchResults: searchResults}, () => {
      ok(flickrSearch.refs.flickrSearchControlNext && flickrSearch.refs.flickrSearchControlPrev, 
      'next and previous both appeared');
      start();
    });
  });

  asyncTest('it increments the page count when next is clicked', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );
    let called = false;
    flickrSearch.incrementPageCount = () => called = true;

    var searchResults = getDummySearchResults(2);

    flickrSearch.setState({page: 1, searchResults: searchResults}, () => {
      TestUtils.Simulate.click(flickrSearch.refs.flickrSearchControlNext);
      ok(called, 'clicking next called incrementPageCount');
      start();
    });
  });

  asyncTest('it decrements the page count when previous is clicked', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );
    let called = false;
    flickrSearch.decrementPageCount = () => called = true;

    var searchResults = getDummySearchResults(2);

    flickrSearch.setState({page: 2, searchResults: searchResults}, () => {
      TestUtils.Simulate.click(flickrSearch.refs.flickrSearchControlPrev);
      ok(called, 'clicking previous called decrementPageCount');
      start();
    });    
  });

  asyncTest('it renders search results', () => {
    const flickrSearch = TestUtils.renderIntoDocument(
      <FlickrSearch />
    );

    var searchResults = getDummySearchResults(1);

    flickrSearch.setState({searchResults: searchResults}, () => {
      ok(TestUtils.scryRenderedDOMComponentsWithClass(flickrSearch, "FlickrImage").length === 3, 
         'rendered flickr search results');
      start();
    });    
  });

});