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

import Backbone from '@canvas/backbone'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('View', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('defaults', () => {
    class SomeView extends Backbone.View {
      static initClass() {
        this.prototype.defaults = {foo: 'bar'}
      }
    }
    SomeView.initClass()
    let view = new SomeView()
    expect(view.options.foo).toBe('bar')
    view = new SomeView({foo: 'baz'})
    expect(view.options.foo).toBe('baz')
    expect(SomeView.prototype.defaults.foo).toBe('bar')
  })

  it('els config', () => {
    class SomeView extends Backbone.View {
      static initClass() {
        this.prototype.els = {'.foo': '$bar'}
      }

      template() {
        return "<div class='foo'>foo</div>"
      }
    }
    SomeView.initClass()
    const view = new SomeView()
    view.render()
    expect(view.$bar.html()).toBe('foo')
  })

  it('children should have a list of child views', () => {
    class SomeView extends Backbone.View {
      static initClass() {
        this.child('test', '.test')
      }
    }
    SomeView.initClass()
    const view = new SomeView({test: new Backbone.View()})
    expect(view.children.length).toBe(1)
  })

  it('template optionProperty', () => {
    const view = new Backbone.View({
      template() {
        return 'hi'
      },
    })
    view.render()
    expect(view.$el.html()).toBe('hi')
  })

  it('child views', () => {
    class ChildView extends Backbone.View {
      template() {
        return 'hi'
      }
    }
    class ParentView extends Backbone.View {
      static initClass() {
        this.optionProperty(this, 'fart')
        this.child('childView', '#child')
      }

      template() {
        return "<div id='child'></div>"
      }
    }
    ParentView.initClass()
    const child = new ChildView()
    const parent = new ParentView({
      childView: child,
      fart: 'fart',
    })
    parent.render()
    expect(parent.$el.find('#child').html()).toBe('hi')
    expect(parent.childView).toBeDefined()
  })

  it('initialize', () => {
    const model = new Backbone.Model()
    const collection = new Backbone.Collection()
    const view = new Backbone.View({
      model,
      collection,
    })
    expect(view.$el.data('view')).toBe(view)
    expect(model.view).toBe(view)
    expect(collection.view).toBe(view)
  })

  it('render', () => {
    class SomeView extends Backbone.View {
      template() {
        return 'hi'
      }
    }
    const view = new SomeView()
    view.render()
    expect(view.$el.html()).toBe('hi')
  })

  it('data-bind', () => {
    class SomeView extends Backbone.View {
      static initClass() {
        this.prototype.els = {
          '#name': '$name',
          '#title': '$title',
        }
      }

      template({name, title}) {
        return `<i id='name' data-bind='name'>${name}</i>
<i id='title' data-bind='title'>${title}</i>`
      }

      format(attr, value) {
        if (attr === 'title') {
          return 'formatted'
        } else {
          return value
        }
      }
    }
    SomeView.initClass()
    const model = new Backbone.Model()
    const view = new SomeView({model})
    view.render()
    model.set('name', 'ryanf')
    expect(view.$name.html()).toBe('ryanf')
    model.set('name', 'jon')
    expect(view.$name.html()).toBe('jon')
    model.set('title', 'engineer')
    expect(view.$title.html()).toBe('formatted')
  })

  it('toJSON', () => {
    let view = new Backbone.View({foo: 'bar'})
    let expected = {
      foo: 'bar',
      cid: view.cid,
      ENV,
    }
    expect(view.toJSON()).toEqual(expected)
    const collection = new Backbone.Collection()
    collection.toJSON = () => ({foo: 'bar'})
    view = new Backbone.View({collection})
    expected = {
      foo: 'bar',
      cid: view.cid,
      ENV,
    }
    expect(view.toJSON()).toEqual(expected)
    collection.present = () => ({foo: 'baz'})
    expected = {
      foo: 'baz',
      cid: view.cid,
      ENV,
    }
    expect(view.toJSON()).toEqual(expected)
    const model = new Backbone.Model()
    model.toJSON = () => ({foo: 'qux'})
    view.model = model
    expected = {
      foo: 'qux',
      cid: view.cid,
      ENV,
    }
    expect(view.toJSON()).toEqual(expected)
    model.present = () => ({foo: 'quux'})
    expected = {
      foo: 'quux',
      cid: view.cid,
      ENV,
    }
    expect(view.toJSON()).toEqual(expected)
  })

  it('View.mixin', () => {
    const mixin1 = {
      events: {'click .foo': 'foo'},
      foo() {
        expect(true).toBeTruthy()
      },
    }
    const mixin2 = {
      events: {'click .bar': 'bar'},
      bar() {
        expect(true).toBeTruthy()
      },
    }
    class SomeView extends Backbone.View {
      static initClass() {
        this.prototype.events = {'click .baz': 'baz'}
        this.mixin(mixin1, mixin2)
      }

      baz() {
        expect(true).toBeTruthy()
      }
    }
    SomeView.initClass()
    const view = new SomeView()
    const expectedEvents = {
      'click .foo': 'foo',
      'click .bar': 'bar',
      'click .baz': 'baz',
    }
    expect(view.events).toEqual(expectedEvents)
    view.foo()
    view.bar()
  })
})
