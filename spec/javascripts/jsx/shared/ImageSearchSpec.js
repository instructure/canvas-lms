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
import ImageSearch from 'ui/features/course_settings/react/components/ImageSearch'
import $ from 'jquery'

QUnit.module('ImageSearch View', {
  setup: () => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  },
  teardown: () => {
    $('#flash_screenreader_holder').remove()
  },
})

const getDummySearchResults = () => {
  const photos = [
    {
      id: 'crazy_id_1',
      alt: 'alt desc for photo 1',
      description: 'desc for photo 1',
      raw_url: 'url1',
    },
    {
      id: 'crazy_id_2',
      description: 'desc for photo 2',
      raw_url: 'url2',
    },
    {
      id: 'crazy_id_3',
      description: null,
      raw_url: 'url3',
    },
  ]

  return photos
}

test('it renders', () => {
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)
  ok(imageSearch)
})

test('it searches for images on input change', () => {
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)
  let called = false
  imageSearch.search = () => (called = true)

  const searchInput = TestUtils.findRenderedDOMComponentWithTag(imageSearch, 'input')
  searchInput.value = 'foos'

  const fakeInputEvent = {
    target: searchInput,
    preventDefault: () => {},
  }

  imageSearch.handleInput(fakeInputEvent)

  ok(called, 'search was called')
})

test('it clears search results when input is cleared', () => {
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)
  let called = false
  imageSearch.clearResults = () => (called = true)
  imageSearch.search = () => {} // stub out so as not to hit actual search api

  const searchInput = TestUtils.findRenderedDOMComponentWithTag(imageSearch, 'input')
  searchInput.value = ''

  const fakeInputEvent = {
    target: searchInput,
    preventDefault: () => {},
  }

  imageSearch.handleInput(fakeInputEvent)

  ok(called, 'clearResults was called')
})

test('it hides previous and next when there is only one page of results', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()

  imageSearch.setState({searchResults, prevUrl: null, nextUrl: null}, () => {
    ok(
      Boolean(!imageSearch._imageSearchControlNext && !imageSearch._imageSearchControlPrev),
      'next and previous are not present'
    )
    done()
  })
})

test('it only renders next page when there is a next-page', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()

  imageSearch.setState({searchResults, prevUrl: null, nextUrl: 'http://next'}, () => {
    ok(
      Boolean(imageSearch._imageSearchControlNext && !imageSearch._imageSearchControlPrev),
      'next button is present'
    )
    done()
  })
})

test('it only renders previous when there is a previous-page', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()

  imageSearch.setState({searchResults, prevUrl: 'http://prev', nextUrl: null}, () => {
    ok(
      Boolean(!imageSearch._imageSearchControlNext && imageSearch._imageSearchControlPrev),
      'previous button is present'
    )
    done()
  })
})

test('it enables next and previous when there are both next and previous pages', assert => {
  const done = assert.async()
  const image = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()

  image.setState({searchResults, prevUrl: 'http://prev', nextUrl: 'http://next'}, () => {
    ok(
      Boolean(image._imageSearchControlNext && image._imageSearchControlPrev),
      'next and previous are both present'
    )
    done()
  })
})

test('it loads next page of results when next is clicked', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)
  let called = false
  imageSearch.loadNextPage = () => (called = true)

  const searchResults = getDummySearchResults()

  imageSearch.setState({searchResults, prevUrl: null, nextUrl: 'http://next'}, () => {
    TestUtils.Simulate.click(imageSearch._imageSearchControlNext)
    ok(called, 'clicking next triggered next results action')
    done()
  })
})

test('it loads previous page of results when previous is clicked', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)
  let called = false
  imageSearch.loadPreviousPage = () => (called = true)

  const searchResults = getDummySearchResults()

  imageSearch.setState({searchResults, prevUrl: 'http://prev', nextUrl: null}, () => {
    TestUtils.Simulate.click(imageSearch._imageSearchControlPrev)
    ok(called, 'clicking previous triggered previous results action')
    done()
  })
})

test('it renders search results', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()

  imageSearch.setState({searchResults}, () => {
    strictEqual(
      TestUtils.scryRenderedDOMComponentsWithClass(imageSearch, 'ImageSearch__item').length,
      3,
      'rendered image search results'
    )
    done()
  })
})

test('it shows text when no results found', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  imageSearch.setState({searchResults: [], searchTerm: 'lkjlkj', alert: 'failure'}, () => {
    strictEqual(
      TestUtils.findRenderedDOMComponentWithClass(imageSearch, 'ImageSearch__images').innerText,
      'No results found for lkjlkj',
      'rendered no search results'
    )
    done()
  })
})

test('it shows appropriate alt text for results', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()
  imageSearch.setState({searchResults, searchTerm: 'cats'}, () => {
    const images = TestUtils.scryRenderedDOMComponentsWithClass(imageSearch, 'ImageSearch__img')
    strictEqual(images[0].alt, 'alt desc for photo 1')
    strictEqual(images[1].alt, 'desc for photo 2')
    strictEqual(images[2].alt, 'cats')
    done()
  })
})

test('it announces when search results are returned for screenreaders', assert => {
  const done = assert.async()
  const imageSearch = TestUtils.renderIntoDocument(<ImageSearch />)

  const searchResults = getDummySearchResults()
  imageSearch.setState({searchResults, searchTerm: 'cats', alert: 'success'}, () => {
    const srElement = $('body').find('#flash_screenreader_holder')
    setTimeout(() => {
      strictEqual(srElement.text(), '3 images found for cats')
      done()
    })
  })
})
