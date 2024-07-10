/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import 'jquery-migrate'
import {Collection, Model} from '..'
import sinon from 'sinon'

class TestCollection extends Collection {}
TestCollection.prototype.defaults = {
  foo: 'bar',
  params: {
    multi: ['foos', 'bars'],
    single: 1,
  },
}
TestCollection.optionProperty('foo')
TestCollection.prototype.url = '/fake'
TestCollection.prototype.model = Model.extend()

describe('Collection', () => {
  let xhr
  let ajaxSpy

  beforeEach(() => {
    xhr = sinon.useFakeXMLHttpRequest()
    ajaxSpy = jest.spyOn($, 'ajax')
  })

  afterEach(() => {
    xhr.restore()
    jest.restoreAllMocks()
  })

  test('default options', () => {
    const collection = new TestCollection()
    expect(typeof collection.options).toBe('object')
    expect(collection.options.foo).toBe('bar')

    const collection2 = new TestCollection(null, {foo: 'baz'})
    expect(collection2.options.foo).toBe('baz')
  })

  test('optionProperty', () => {
    const collection = new TestCollection({foo: 'bar'})
    expect(collection.foo).toBe('bar')
  })

  test('sends @params in request', () => {
    const collection = new TestCollection()
    collection.fetch()
    expect($.ajax.mock.calls[0][0].data).toEqual(collection.options.params)

    collection.options.params = {a: 'b', c: ['d']}
    collection.fetch()
    expect($.ajax.mock.calls[1][0].data).toEqual(collection.options.params)
  })

  test('uses conventional default url', () => {
    const assetString = 'course_1'
    const FakeModel = Model.extend({resourceName: 'discussion_topics'})

    const FakeCollection = Collection.extend({
      model: FakeModel,
    })

    const collection = new FakeCollection()
    collection.contextAssetString = assetString

    expect(collection.url()).toBe('/api/v1/courses/1/discussion_topics')
  })

  test('triggers setParam event', () => {
    const collection = new Collection()
    const spy = jest.fn()
    collection.on('setParam', spy)
    collection.setParam('foo', 'bar')
    expect(spy).toHaveBeenCalledTimes(1)
    expect(spy).toHaveBeenCalledWith('foo', 'bar')
  })

  test('setParams', () => {
    const collection = new Collection()
    expect(collection.options.params).toBeFalsy()
    collection.setParams({
      foo: 'bar',
      baz: 'qux',
    })
    expect(collection.options.params).toEqual({foo: 'bar', baz: 'qux'})
  })

  test('triggers setParams event', () => {
    const collection = new Collection()
    const spy = jest.fn()
    collection.on('setParams', spy)
    const params = {
      foo: 'bar',
      baz: 'qux',
    }
    collection.setParams(params)
    expect(spy).toHaveBeenCalledTimes(1)
    expect(spy).toHaveBeenCalledWith(params)
  })

  test('parse', () => {
    class SideLoader extends Collection {}
    const collection = new SideLoader()

    // boolean
    SideLoader.prototype.sideLoad = {author: true}

    let document = [1, 2, 3]
    expect(collection.parse(document)).toBe(document)

    document = {a: 1, b: 2}
    expect(collection.parse(document)).toBe(document)

    document = {
      meta: {},
      posts: [
        {id: 1, links: {author: 1}},
        {id: 2, links: {author: 1}},
      ],
    }
    expect(collection.parse(document)).toEqual(document.posts)

    const john = {id: 1, name: 'John Doe'}
    document = {
      posts: [
        {id: 1, links: {author: 1}},
        {id: 2, links: {author: 1}},
      ],
      linked: {
        authors: [john],
      },
    }
    let expected = [
      {id: 1, author: john},
      {id: 2, author: john},
    ]
    expect(collection.parse(document)).toEqual(expected)

    // string
    SideLoader.prototype.sideLoad = {author: 'users'}

    document = {
      posts: [
        {id: 1, links: {author: 1}},
        {id: 2, links: {author: 1}},
      ],
      linked: {
        users: [john],
      },
    }
    expect(collection.parse(document)).toEqual(expected)

    // complex
    SideLoader.prototype.sideLoad = {
      author: {
        collection: 'users',
        foreignKey: 'user_id',
      },
    }

    document = {
      posts: [
        {id: 1, links: {user_id: 1}},
        {id: 2, links: {user_id: 1}},
      ],
      linked: {
        users: [john],
      },
    }
    expect(collection.parse(document)).toEqual(expected)

    // multiple
    SideLoader.prototype.sideLoad = {
      author: 'users',
      editor: 'users',
    }

    let jane = {id: 2, name: 'Jane Doe'}
    document = {
      posts: [
        {id: 1, links: {author: 1, editor: 2}},
        {id: 2, links: {author: 2, editor: 1}},
      ],
      linked: {
        users: [john, jane],
      },
    }
    expected = [
      {id: 1, author: john, editor: jane},
      {id: 2, author: jane, editor: john},
    ]
    expect(collection.parse(document)).toEqual(expected)

    // keeps links attributes that are not found or not defined
    SideLoader.prototype.sideLoad = {author: 'users'}

    jane = {id: 2, name: 'Jane Doe'}
    document = {
      posts: [
        {id: 1, links: {author: 1, editor: 2}},
        {id: 2, links: {author: 2, editor: 1}},
        {id: 3, links: {author: 5, editor: 1}},
      ],
      linked: {
        users: [john, jane],
      },
    }
    expected = [
      {id: 1, author: john, links: {editor: 2}},
      {id: 2, author: jane, links: {editor: 1}},
      {id: 3, links: {author: 5, editor: 1}},
    ]
    expect(collection.parse(document)).toEqual(expected)

    // to_many simple
    SideLoader.prototype.sideLoad = {authors: true}

    document = {
      posts: [
        {id: 1, links: {authors: ['1', '2']}},
        {id: 2, links: {authors: ['1']}},
      ],
      linked: {
        authors: [john, jane],
      },
    }

    expected = [
      {id: 1, authors: [john, jane]},
      {id: 2, authors: [john]},
    ]

    expect(collection.parse(document)).toEqual(expected)

    // to_many string
    SideLoader.prototype.sideLoad = {authors: 'users'}

    document = {
      posts: [
        {id: 1, links: {authors: ['1', '2']}},
        {id: 2, links: {authors: ['1']}},
      ],
      linked: {
        users: [john, jane],
      },
    }

    expected = [
      {id: 1, authors: [john, jane]},
      {id: 2, authors: [john]},
    ]

    expect(collection.parse(document)).toEqual(expected)

    // to_many complex
    SideLoader.prototype.sideLoad = {
      authors: {
        collection: 'users',
        foreignKey: 'author_ids',
      },
    }

    document = {
      posts: [
        {id: 1, links: {author_ids: ['1', '2']}},
        {id: 2, links: {author_ids: ['1']}},
      ],
      linked: {
        users: [john, jane],
      },
    }

    expected = [
      {id: 1, authors: [john, jane]},
      {id: 2, authors: [john]},
    ]

    expect(collection.parse(document)).toEqual(expected)

    // to_many complex
    SideLoader.prototype.sideLoad = {
      authors: {
        collection: 'authors',
        foreignKey: 'author_ids',
      },
    }

    document = {
      posts: [
        {id: 1, links: {author_ids: ['1', '2']}},
        {id: 2, links: {author_ids: ['1']}},
      ],
      linked: {
        users: [john, jane],
      },
    }

    expected = "Could not find linked collection for 'authors' using 'author_ids'."

    expect(() => collection.parse(document)).toThrow(expected)

    SideLoader.prototype.sideLoad = {authors: true}

    // Links attribute
    document = {
      links: {
        'posts.author': 'http://example.com/authors/{posts.author}',
      },
      posts: [
        {id: 1, links: {authors: ['1', '2']}},
        {id: 2, links: {authors: ['1']}},
      ],
      linked: {
        authors: [john, jane],
      },
    }

    expected = [
      {id: 1, authors: [john, jane]},
      {id: 2, authors: [john]},
    ]

    expect(collection.parse(document)).toEqual(expected)
  })
})
