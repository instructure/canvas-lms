/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import ImageSearch from 'jsx/shared/ImageSearch'

QUnit.module('ImageSearch View');

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
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );
  ok(imageSearch);
});

test('it searches for images on input change', () => {
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );
  let called = false;
  imageSearch.search = () => called = true;

  const searchInput = TestUtils.findRenderedDOMComponentWithTag(imageSearch, "input");
  searchInput.value = "foos";

  const fakeInputEvent = {
    target: searchInput,
    preventDefault: () => {}
  };

  imageSearch.handleInput(fakeInputEvent);

  ok(called, 'search was called');
});

test('it clears search results when input is cleared', () => {
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );
  let called = false;
  imageSearch.clearResults = () => called = true;
  imageSearch.search = () => {}; // stub out so as not to hit actual search api

  const searchInput = TestUtils.findRenderedDOMComponentWithTag(imageSearch, "input");
  searchInput.value = "";

  const fakeInputEvent = {
    target: searchInput,
    preventDefault: () => {}
  };

  imageSearch.handleInput(fakeInputEvent);

  ok(called, 'clearResults was called');
});

test('it does not render next or previous page buttons when there is only one page of results', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );

  const searchResults = getDummySearchResults(1);

  imageSearch.setState({searchResults}, () => {
    ok(
      !imageSearch.refs.imageSearchControlNext && !imageSearch.refs.imageSearchControlPrev,
      'next and previous did not appear'
    );
    done();
  });
});

test('it only renders next when there is more than one page of results and it is not on the last page', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );

  const searchResults = getDummySearchResults(2);

  imageSearch.setState({searchResults}, () => {
    ok(
      imageSearch.refs.imageSearchControlNext && !imageSearch.refs.imageSearchControlPrev,
      'only next button appeared'
    );
    done();
  });
});

test('it only renders previous when there is more than one page of results and it is not on the first page', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );

  const searchResults = getDummySearchResults(2);

  imageSearch.setState({page: 2, searchResults}, () => {
    ok(!imageSearch.refs.imageSearchControlNext && imageSearch.refs.imageSearchControlPrev,
      'only previous button appeared');
    done();
  });
});

test('it renders next and previous when there is more than one page of results and it is on a page in-between', assert => {
  const done = assert.async()
  const image = TestUtils.renderIntoDocument(
    <ImageSearch />
  );

  const searchResults = getDummySearchResults(3);

  image.setState({page: 2, searchResults}, () => {
    ok(image.refs.imageSearchControlNext && image.refs.imageSearchControlPrev,
    'next and previous both appeared');
    done();
  });
});

test('it increments the page count when next is clicked', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );
  let called = false;
  imageSearch.incrementPageCount = () => called = true;

  const searchResults = getDummySearchResults(2);

  imageSearch.setState({page: 1, searchResults}, () => {
    TestUtils.Simulate.click(ReactDOM.findDOMNode(imageSearch.refs.imageSearchControlNext));
    ok(called, 'clicking next called incrementPageCount');
    done();
  });
});

test('it decrements the page count when previous is clicked', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );
  let called = false;
  imageSearch.decrementPageCount = () => called = true;

  const searchResults = getDummySearchResults(2);

  imageSearch.setState({page: 2, searchResults}, () => {
    TestUtils.Simulate.click(ReactDOM.findDOMNode(imageSearch.refs.imageSearchControlPrev));
    ok(called, 'clicking previous called decrementPageCount');
    done();
  });
});

test('it renders search results', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(
    <ImageSearch />
  );

  const searchResults = getDummySearchResults(1);

  imageSearch.setState({searchResults}, () => {
    strictEqual(
      TestUtils.scryRenderedDOMComponentsWithClass(imageSearch, "ImageSearch__item").length,
      3,
      'rendered image search results'
    );
    done();
  });
});
