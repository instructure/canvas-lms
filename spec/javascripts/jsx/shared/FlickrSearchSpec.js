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

import React from 'react'
import TestUtils from 'react-addons-test-utils'
import FlickrSearch from 'jsx/shared/FlickrSearch'

QUnit.module('FlickrSearch View');

const getDummySearchResults = (pageCount) => {
  const photo = [{
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

  const photos = {
    pages: pageCount,
    photo
  };

  return {photos};
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

  const flickrInput = TestUtils.findRenderedDOMComponentWithClass(flickrSearch, "ic-Input");
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
  flickrSearch.searchFlickr = () => {}; // stub out so as not to hit actual flickr api

  const flickrInput = TestUtils.findRenderedDOMComponentWithClass(flickrSearch, "ic-Input");
  flickrInput.value = "";

  const fakeInputEvent = {
    target: flickrInput,
    preventDefault: () => {}
  };

  flickrSearch.handleInput(fakeInputEvent);

  ok(called, 'clearFlickrResults was called');
});

test('it does not render next or previous page buttons when there is only one page of results', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );

  const searchResults = getDummySearchResults(1);

  flickrSearch.setState({searchResults}, () => {
    ok(
      !flickrSearch.refs.flickrSearchControlNext && !flickrSearch.refs.flickrSearchControlPrev,
      'next and previous did not appear'
    );
    done();
  });
});

test('it only renders next when there is more than one page of results and it is not on the last page', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );

  const searchResults = getDummySearchResults(2);

  flickrSearch.setState({searchResults}, () => {
    ok(
      flickrSearch.refs.flickrSearchControlNext && !flickrSearch.refs.flickrSearchControlPrev,
      'only next button appeared'
    );
    done();
  });
});

test('it only renders previous when there is more than one page of results and it is not on the first page', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );

  const searchResults = getDummySearchResults(2);

  flickrSearch.setState({page: 2, searchResults}, () => {
    ok(!flickrSearch.refs.flickrSearchControlNext && flickrSearch.refs.flickrSearchControlPrev,
      'only previous button appeared');
    done();
  });
});

test('it renders next and previous when there is more than one page of results and it is on a page inbetween', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );

  const searchResults = getDummySearchResults(3);

  flickrSearch.setState({page: 2, searchResults}, () => {
    ok(flickrSearch.refs.flickrSearchControlNext && flickrSearch.refs.flickrSearchControlPrev,
    'next and previous both appeared');
    done();
  });
});

test('it increments the page count when next is clicked', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );
  let called = false;
  flickrSearch.incrementPageCount = () => called = true;

  const searchResults = getDummySearchResults(2);

  flickrSearch.setState({page: 1, searchResults}, () => {
    TestUtils.Simulate.click(flickrSearch.refs.flickrSearchControlNext);
    ok(called, 'clicking next called incrementPageCount');
    done();
  });
});

test('it decrements the page count when previous is clicked', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );
  let called = false;
  flickrSearch.decrementPageCount = () => called = true;

  const searchResults = getDummySearchResults(2);

  flickrSearch.setState({page: 2, searchResults}, () => {
    TestUtils.Simulate.click(flickrSearch.refs.flickrSearchControlPrev);
    ok(called, 'clicking previous called decrementPageCount');
    done();
  });
});

test('it renders search results', assert => {
  const done = assert.async()
  const flickrSearch = TestUtils.renderIntoDocument(
    <FlickrSearch />
  );

  const searchResults = getDummySearchResults(1);

  flickrSearch.setState({searchResults}, () => {
    strictEqual(
      TestUtils.scryRenderedDOMComponentsWithClass(flickrSearch, "FlickrImage").length,
      3,
      'rendered flickr search results'
    );
    done();
  });
});
