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

import {Model} from '../index'

describe('Backbone.Model', () => {
  let model

  beforeEach(() => {
    model = new Model()
  })

  test('@mixin', () => {
    const initSpy = jest.fn()
    const mixable = {
      defaults: {cash: 'money'},
      initialize: initSpy,
    }

    class Mixed extends Model {
      static initClass() {
        this.mixin(mixable)
      }

      initialize() {
        initSpy.apply(this, arguments)
        super.initialize(...arguments)
      }
    }

    Mixed.initClass()
    const model_ = new Mixed()
    expect(model_.get('cash')).toBe('money')
    expect(initSpy).toHaveBeenCalledTimes(2)
  })

  test('increment', () => {
    const model_ = new Model({count: 1})
    model_.increment('count', 2)
    expect(model_.get('count')).toBe(3)
  })

  test('decrement', () => {
    const model_ = new Model({count: 10})
    model_.decrement('count', 7)
    expect(model_.get('count')).toBe(3)
  })

  test('#deepGet returns nested attributes', () => {
    model.attributes = {foo: {bar: {zing: 'cats'}}}
    const value = model.deepGet('foo.bar.zing')
    expect(value).toBe('cats')
  })
})
