/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import QuizCollection from '../../collections/QuizCollection'
import QuizItemGroupView from '../QuizItemGroupView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import assertions from '@canvas/test-utils/assertionsSpec'
import '@canvas/jquery/jquery.simulate'
import 'jqueryui/tooltip'
import {waitFor} from '@testing-library/dom'

const createView = function (collection) {
  if (collection == null) {
    collection = new QuizCollection([
      {
        id: 1,
        title: 'Foo',
        permissions: {delete: true},
      },
      {
        id: 2,
        title: 'Bar',
        permissions: {delete: true},
      },
    ])
  }
  const view = new QuizItemGroupView({collection, listId: 'assignment-quizzes'})
  view.$el.appendTo($('#fixtures'))
  return view.render()
}

describe('QuizItemGroupView', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('should be accessible', async () => {
    const view = createView()
    await assertions.isAccessible(view, {a11yReport: true})
  })

  it('#isEmpty is false if any items aren’t hidden', () => {
    const view = createView()
    expect(view.isEmpty()).toBe(false)
  })

  it('#isEmpty is true if collection is empty', () => {
    const collection = new QuizCollection([])
    const view = createView(collection)
    expect(view.isEmpty()).toBe(true)
  })

  it('#isEmpty is true if all items are hidden', () => {
    const collection = new QuizCollection([
      {id: 1, hidden: true},
      {id: 2, hidden: true},
    ])
    const view = createView(collection)
    expect(view.isEmpty()).toBe(true)
  })

  it('should filter models with title that doesn’t match term', () => {
    const view = createView()
    const model = new Quiz({title: 'Foo Name'})

    expect(view.filter(model, 'name')).toBe(true)
    expect(view.filter(model, 'zzz')).toBe(false)
  })

  it('should not use regexp to filter models', () => {
    const view = createView()
    const model = new Quiz({title: 'Foo Name'})

    expect(view.filter(model, '.*name')).toBe(false)
    expect(view.filter(model, 'zzz')).toBe(false)
  })

  it('should filter models with multiple terms', () => {
    const view = createView()
    const model = new Quiz({title: 'Foo Name bar'})

    expect(view.filter(model, 'name bar')).toBe(true)
    expect(view.filter(model, 'zzz')).toBe(false)
  })

  it('should rerender on filter change', () => {
    const view = createView()
    expect(view.$el.find('.collectionViewItems li.quiz')).toHaveLength(2)

    view.filterResults('foo')
    expect(view.$el.find('.collectionViewItems li.quiz')).toHaveLength(1)
  })

  it('should not render no content message if quizzes are available', () => {
    const view = createView()
    expect(view.$el.find('.collectionViewItems li.quiz')).toHaveLength(2)
    expect(view.$el.find('.no_content').is(':visible')).toBe(false)
  })

  it('should render no content message if no quizzes available', async () => {
    const collection = new QuizCollection([])
    const view = createView(collection)
    expect(view.$el.find('.collectionViewItems li.quiz')).toHaveLength(0)
    const noContentElement = view.$el.find('.no_content')
    expect(noContentElement).toHaveLength(1)
    await waitFor(() => {
      const computedStyle = getComputedStyle(noContentElement[0])
      expect(computedStyle.display).not.toBe('none')
    })
  })

  it('clicking the header should toggle arrow state', () => {
    const view = createView()

    expect(view.$('.element_toggler i').hasClass('icon-mini-arrow-down')).toBe(true)
    expect(view.$('.element_toggler i').hasClass('icon-mini-arrow-right')).toBe(false)

    view.$('.element_toggler').simulate('click')

    expect(view.$('.element_toggler i').hasClass('icon-mini-arrow-down')).toBe(false)
    expect(view.$('.element_toggler i').hasClass('icon-mini-arrow-right')).toBe(true)
  })
})
