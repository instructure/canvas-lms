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

import Backbone from 'Backbone'
import mixing from 'compiled/util/mixin'
import fakeENV from 'helpers/fakeENV'

QUnit.module('View', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('defaults', function() {
  class SomeView extends Backbone.View {
    static initClass() {
      this.prototype.defaults = {foo: 'bar'}
    }
  }
  SomeView.initClass()
  let view = new SomeView()
  equal(view.options.foo, 'bar', 'recieves default')
  view = new SomeView({foo: 'baz'})
  equal(view.options.foo, 'baz', 'overrides default')
  equal(SomeView.prototype.defaults.foo, 'bar', "doesn't extend prototype")
})

test('els config', function() {
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
  equal(view.$bar.html(), 'foo', 'cached element')
})

test('optionProperty', function() {
  class SomeView extends Backbone.View {
    static initClass() {
      this.optionProperty('foo')
    }
  }
  SomeView.initClass()
  let view = new SomeView({foo: 'bar'})
  equal(view.foo, 'bar', 'set option as instance property')
  view = new Backbone.View({foo: 'bar'})
  ok(view.foo == null, 'parent class property options not poluted')
})

test('children should have a list of child views', function() {
  class SomeView extends Backbone.View {
    static initClass() {
      this.child('test', '.test')
    }
  }
  SomeView.initClass()
  const view = new SomeView({test: new Backbone.View()})
  equal(view.children.length, 1, 'Creates an array of children view stored on .children')
})

test('template optionProperty', () => {
  const view = new Backbone.View({
    template() {
      return 'hi'
    }
  })
  view.render()
  equal(view.$el.html(), 'hi', 'template rendered with view as option')
})

test('child views', function() {
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
    fart: 'fart'
  })
  parent.render()
  equal(parent.$el.find('#child').html(), 'hi', 'child view rendered')
  ok(parent.childView, 'childView assigned as instance property')
})

test('initialize', () => {
  const model = new Backbone.Model()
  const collection = new Backbone.Collection()
  const view = new Backbone.View({
    model,
    collection
  })
  equal(view.$el.data('view'), view, 'view stored on element data')
  equal(model.view, view, 'sets model.view to the view')
  equal(collection.view, view, 'sets collection.view to the view')
})

test('render', () => {
  class SomeView extends Backbone.View {
    template() {
      return 'hi'
    }
  }
  const view = new SomeView()
  view.render()
  equal(view.$el.html(), 'hi', 'renders template')
})

test('data-bind', function() {
  class SomeView extends Backbone.View {
    static initClass() {
      this.prototype.els = {
        '#name': '$name',
        '#title': '$title'
      }
    }
    template({name, title}) {
      return `\
<i id='name' data-bind='name'>${name}</i>
<i id='title' data-bind='title'>${title}</i>\
`
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
  equal(view.$name.html(), 'ryanf', 'set template to model data')
  model.set('name', 'jon')
  equal(view.$name.html(), 'jon', 'element html kept up-to-date')
  model.set('title', 'engineer')
  equal(view.$title.html(), 'formatted', 'formatting applied')
})

test('toJSON', () => {
  let view = new Backbone.View({foo: 'bar'})
  let expected = {
    foo: 'bar',
    cid: view.cid,
    ENV
  }
  deepEqual(expected, view.toJSON(), 'returns options')
  const collection = new Backbone.Collection()
  collection.toJSON = () => ({foo: 'bar'})
  view = new Backbone.View({collection})
  expected = {
    foo: 'bar',
    cid: view.cid,
    ENV
  }
  deepEqual(expected, view.toJSON(), 'uses @collection.toJSON')
  collection.present = () => ({foo: 'baz'})
  expected = {
    foo: 'baz',
    cid: view.cid,
    ENV
  }
  deepEqual(expected, view.toJSON(), 'uses @collection.present over toJSON')
  const model = new Backbone.Model()
  model.toJSON = () => ({foo: 'qux'})
  view.model = model
  expected = {
    foo: 'qux',
    cid: view.cid,
    ENV
  }
  deepEqual(expected, view.toJSON(), 'uses @model.toJSON over @collection')
  model.present = () => ({foo: 'quux'})
  expected = {
    foo: 'quux',
    cid: view.cid,
    ENV
  }
  deepEqual(expected, view.toJSON(), 'uses @model.present over toJSON')
})

test('View.mixin', 3, function() {
  const mixin1 = {
    events: {'click .foo': 'foo'},
    foo() {
      ok(true, 'called mixin1.foo')
    }
  }
  const mixin2 = {
    events: {'click .bar': 'bar'},
    bar() {
      ok(true, 'called mixin2.bar')
    }
  }
  class SomeView extends Backbone.View {
    static initClass() {
      this.prototype.events = {'click .baz': 'baz'}
      this.mixin(mixin1, mixin2)
    }
    baz() {
      ok(true, 'called prototype method baz')
    }
  }
  SomeView.initClass()
  const view = new SomeView()
  const expectedEvents = {
    'click .foo': 'foo',
    'click .bar': 'bar',
    'click .baz': 'baz'
  }
  deepEqual(view.events, expectedEvents, 'events merged properly')
  view.foo()
  return view.bar()
})

test('View.mixin initialize, attach and afterRender magic tricks', function() {
  const mixin1 = {
    initialize: sinon.spy(),
    attach: sinon.spy(),
    afterRender: sinon.spy()
  }
  const mixin2 = {
    initialize: sinon.spy(),
    attach: sinon.spy(),
    afterRender: sinon.spy()
  }
  class SomeView extends Backbone.View {
    static initClass() {
      this.mixin(mixin1, mixin2)
    }
  }
  SomeView.initClass()
  const view = new SomeView()
  view.render()
  ok(mixin1.initialize.calledOnce, 'called mixin1 initialize')
  ok(mixin2.initialize.calledOnce, 'called mixin2 initialize')
  ok(mixin1.afterRender.calledOnce, 'called mixin1 afterRender')
  ok(mixin2.afterRender.calledOnce, 'called mixin2 afterRender')
  ok(mixin1.attach.calledOnce, 'called mixin1 attach')
  ok(mixin2.attach.calledOnce, 'called mixin2 attach')
})

test('View.mixin does not merge into parent class', function() {
  const mixin = {defaults: {foo: 'bar'}}
  class Foo extends Backbone.View {
    static initClass() {
      this.mixin(mixin)
    }
  }
  Foo.initClass()
  equal(Backbone.View.prototype.defaults.foo, undefined, 'View::defaults was not appended')
  equal(Foo.prototype.defaults.foo, 'bar', 'Foo::defaults was appended')
})

test('View.mixin with compound mixins', function() {
  const afterRender1 = sinon.spy()
  const mixin1 = {afterRender: afterRender1}
  const afterRender2 = sinon.spy()
  const mixin2 = mixing({}, mixin1, {afterRender: afterRender2})
  const afterRender3 = sinon.spy()
  const mixin3 = {afterRender: afterRender3}
  const afterRenderFoo = sinon.spy()
  class Foo extends Backbone.View {
    static initClass() {
      this.mixin(mixin2, mixin3)
    }
    afterRender() {
      return super.afterRender(...arguments) && afterRenderFoo()
    }
  }
  Foo.initClass()
  window.Foo = Foo
  const view = new Foo()
  view.render()
  ok(afterRender1.calledOnce, 'called mixin1 afterRender')
  ok(afterRender2.calledOnce, 'called mixin2 afterRender')
  ok(afterRender3.calledOnce, 'called mixin3 afterRender')
  ok(afterRenderFoo.calledOnce, 'called foo afterRender')

  // order of mixing in shouldn't matter
  const afterRender4 = sinon.spy()
  const afterRender5 = sinon.spy()
  const afterRender6 = sinon.spy()
  const mixin4 = {afterRender: afterRender4}
  const mixin5 = mixing({}, mixin4, {afterRender: afterRender5})
  const mixin6 = {afterRender: afterRender6}
  const afterRenderBar = sinon.spy()
  class Bar extends Backbone.View {
    static initClass() {
      this.mixin(mixin6, mixin5)
    }
    afterRender() {
      return super.afterRender(...arguments) && afterRenderBar()
    }
  }
  Bar.initClass()
  window.Bar = Bar
  const bar = new Bar()
  bar.render()
  ok(afterRender4.calledOnce, 'called mixin4 afterRender')
  ok(afterRender5.calledOnce, 'called mixin5 afterRender')
  ok(afterRender6.calledOnce, 'called mixin6 afterRender')
  ok(afterRenderBar.calledOnce, 'called bar afterRender')
})
