/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import InputFilterView from '../index'
import '@testing-library/jest-dom'
import {act} from '@testing-library/react'

describe('InputFilterView', () => {
  let view
  let container

  beforeEach(() => {
    jest.useFakeTimers()
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
  })

  afterEach(() => {
    jest.useRealTimers()
    view?.remove()
    container.remove()
  })

  const createAndRenderView = (options = {}) => {
    view = new InputFilterView(options)
    view.render()
    view.$el.appendTo($('#fixtures'))
  }

  const setValue = term => {
    view.el.value = term
  }

  const simulateKeyup = (inputDelay = view.options.onInputDelay) => {
    const event = new KeyboardEvent('keyup', {bubbles: true})
    view.el.dispatchEvent(event)
    act(() => {
      jest.advanceTimersByTime(inputDelay)
    })
  }

  it('fires input event and sends value', () => {
    createAndRenderView()
    const inputHandler = jest.fn()
    view.on('input', inputHandler)

    setValue('foo')
    simulateKeyup()

    expect(inputHandler).toHaveBeenCalledWith('foo')
  })

  it('delays firing the event until input delay has passed', () => {
    createAndRenderView({onInputDelay: 150})
    const inputHandler = jest.fn()
    view.on('input', inputHandler)

    setValue('foo')
    simulateKeyup(150)

    expect(inputHandler).toHaveBeenCalledTimes(1)
  })

  it('does not fire input event if value has not changed', () => {
    createAndRenderView()
    const inputHandler = jest.fn()
    view.on('input', inputHandler)

    setValue('foo')
    simulateKeyup()
    simulateKeyup()

    expect(inputHandler).toHaveBeenCalledTimes(1)
  })

  it('updates the model attribute', () => {
    createAndRenderView()
    view.model = new Backbone.Model()

    setValue('foo')
    simulateKeyup()

    expect(view.model.get('filter')).toBe('foo')
  })

  it('updates the collection parameter', () => {
    createAndRenderView()
    view.collection = new Backbone.Collection()

    setValue('foo')
    simulateKeyup()

    expect(view.collection.options.params.filter).toBe('foo')
  })

  it('gets modelAttribute from input name', () => {
    const input = $('<input name="couch">').appendTo($('#fixtures'))
    view = new InputFilterView({
      el: input[0],
    })

    expect(view.modelAttribute).toBe('couch')
  })

  it('sets model attribute to empty string with empty value', () => {
    createAndRenderView()
    view.model = new Backbone.Model()

    setValue('foo')
    simulateKeyup()
    setValue('')
    simulateKeyup()

    expect(view.model.get('filter')).toBe('')
  })

  it('deletes collection parameter on empty value', () => {
    createAndRenderView()
    view.collection = new Backbone.Collection()

    setValue('foo')
    simulateKeyup()
    expect(view.collection.options.params.filter).toBe('foo')

    setValue('')
    simulateKeyup()
    expect(view.collection.options.params.filter).toBeUndefined()
  })

  it('does nothing with model/collection when the value is less than the minLength', () => {
    createAndRenderView()
    view.model = new Backbone.Model({filter: 'foo'})

    setValue('ab')
    simulateKeyup()

    expect(view.model.get('filter')).toBe('foo')
  })

  it('sets param to false when the value is less than minLength and setParamOnInvalid=true', () => {
    createAndRenderView()
    view.model = new Backbone.Model({filter: 'foo'})
    view.options.setParamOnInvalid = true

    setValue('ab')
    simulateKeyup()

    expect(view.model.get('filter')).toBe(false)
  })

  it('updates filter with small number when allowSmallerNumbers is true', () => {
    createAndRenderView()
    view.model = new Backbone.Model({filter: 'foo'})
    view.options.allowSmallerNumbers = false

    setValue('1')
    simulateKeyup()
    expect(view.model.get('filter')).toBe('foo')

    view.options.allowSmallerNumbers = true
    setValue('2')
    simulateKeyup()
    expect(view.model.get('filter')).toBe('2')
  })
})
