define [
  'Backbone'
  'compiled/util/mixin'
  'helpers/fakeENV'
], (Backbone, mixing, fakeENV) ->
  QUnit.module 'View',
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()

  test 'defaults', ->
    class SomeView extends Backbone.View
      defaults:
        foo: 'bar'
    view = new SomeView
    equal view.options.foo, 'bar', 'recieves default'
    view = new SomeView foo: 'baz'
    equal view.options.foo, 'baz', 'overrides default'
    equal SomeView::defaults.foo, 'bar', "doesn't extend prototype"

  test 'els config', ->
    class SomeView extends Backbone.View
      els:
        '.foo': '$bar'
      template: ->
        "<div class='foo'>foo</div>"
    view = new SomeView
    view.render()
    equal view.$bar.html(), 'foo', 'cached element'

  test 'optionProperty', ->
    class SomeView extends Backbone.View
      @optionProperty 'foo'
    view = new SomeView foo: 'bar'
    equal view.foo, 'bar', 'set option as instance property'
    view = new Backbone.View foo: 'bar'
    ok !view.foo?, 'parent class property options not poluted'

  test 'children should have a list of child views', ->
    class SomeView extends Backbone.View
      @child 'test', '.test'

    view = new SomeView test: new Backbone.View
    equal view.children.length, 1, "Creates an array of children view stored on .children"

  test 'template optionProperty', ->
    view = new Backbone.View
      template: -> "hi"
    view.render()
    equal view.$el.html(), "hi",
      "template rendered with view as option"

  test 'child views', ->
    class ChildView extends Backbone.View
      template: -> "hi"
    class ParentView extends Backbone.View
      @optionProperty this, 'fart'
      @child 'childView', '#child'
      template: ->
        "<div id='child'></div>"
    child = new ChildView
    parent = new ParentView childView: child, fart: 'fart'
    parent.render()
    equal parent.$el.find('#child').html(), 'hi', 'child view rendered'
    ok parent.childView, 'childView assigned as instance property'

  test 'initialize', ->
    model = new Backbone.Model
    collection = new Backbone.Collection
    view = new Backbone.View {model, collection}
    equal view.$el.data('view'), view, 'view stored on element data'
    equal model.view, view, 'sets model.view to the view'
    equal collection.view, view, 'sets collection.view to the view'

  test 'render', ->
    class SomeView extends Backbone.View
      template: -> 'hi'
    view = new SomeView
    view.render()
    equal view.$el.html(), 'hi', 'renders template'

  test 'data-bind', ->
    class SomeView extends Backbone.View
      els:
        '#name': '$name'
        '#title': '$title'
      template: ({name, title})->
        """
        <i id='name' data-bind='name'>#{name}</i>
        <i id='title' data-bind='title'>#{title}</i>
        """
      format: (attr, value) ->
        if attr is 'title'
          'formatted'
        else
          value
    model = new Backbone.Model
    view = new SomeView {model}
    view.render()
    model.set 'name', 'ryanf'
    equal view.$name.html(), 'ryanf', 'set template to model data'
    model.set 'name', 'jon'
    equal view.$name.html(), 'jon', 'element html kept up-to-date'
    model.set 'title', 'engineer'
    equal view.$title.html(), 'formatted', 'formatting applied'

  test 'toJSON', ->
    view = new Backbone.View foo: 'bar'
    expected = foo: 'bar', cid: view.cid, ENV: ENV
    deepEqual expected, view.toJSON(), 'returns options'

    collection = new Backbone.Collection
    collection.toJSON = -> foo: 'bar'
    view = new Backbone.View {collection}
    expected = foo: 'bar', cid: view.cid, ENV: ENV
    deepEqual expected, view.toJSON(), 'uses @collection.toJSON'
    collection.present = -> foo: 'baz'
    expected = foo: 'baz', cid: view.cid, ENV: ENV
    deepEqual expected, view.toJSON(), 'uses @collection.present over toJSON'

    model = new Backbone.Model
    model.toJSON = -> foo: 'qux'
    view.model = model
    expected = foo: 'qux', cid: view.cid, ENV: ENV
    deepEqual expected, view.toJSON(), 'uses @model.toJSON over @collection'
    model.present = -> foo: 'quux'
    expected = foo: 'quux', cid: view.cid, ENV: ENV
    deepEqual expected, view.toJSON(), 'uses @model.present over toJSON'

  test 'View.mixin', 3, ->
    mixin1 =
      events: 'click .foo': 'foo'
      foo: -> ok true, 'called mixin1.foo'
    mixin2 =
      events: 'click .bar': 'bar'
      bar: -> ok true, 'called mixin2.bar'
    class SomeView extends Backbone.View
      events: 'click .baz': 'baz'
      baz: -> ok true, 'called prototype method baz'
      @mixin mixin1, mixin2
    view = new SomeView
    # events are expected to all be merged together
    # rather than getting blown away by the last mixin
    expectedEvents =
      'click .foo': 'foo'
      'click .bar': 'bar'
      'click .baz': 'baz'
    deepEqual view.events, expectedEvents, 'events merged properly'
    # call the handlers manually
    view.foo()
    view.bar()

  test 'View.mixin initialize, attach and afterRender magic tricks', ->
    mixin1 =
      initialize: @spy()
      attach: @spy()
      afterRender: @spy()
    mixin2 =
      initialize: @spy()
      attach: @spy()
      afterRender: @spy()
    class SomeView extends Backbone.View
      @mixin mixin1, mixin2
    view = new SomeView
    view.render()
    ok mixin1.initialize.calledOnce, 'called mixin1 initialize'
    ok mixin2.initialize.calledOnce, 'called mixin2 initialize'
    ok mixin1.afterRender.calledOnce, 'called mixin1 afterRender'
    ok mixin2.afterRender.calledOnce, 'called mixin2 afterRender'
    ok mixin1.attach.calledOnce, 'called mixin1 attach'
    ok mixin2.attach.calledOnce, 'called mixin2 attach'

  test 'View.mixin does not merge into parent class', ->
    mixin = defaults: foo: 'bar'
    class Foo extends Backbone.View
      @mixin mixin
    equal Backbone.View::defaults.foo, undefined, 'View::defaults was not appended'
    equal Foo::defaults.foo, 'bar', 'Foo::defaults was appended'

  test 'View.mixin with compound mixins', ->
    afterRender1 = @spy()
    mixin1 = afterRender: afterRender1
    afterRender2 = @spy()
    mixin2 = mixing {}, mixin1, afterRender: afterRender2
    afterRender3 = @spy()
    mixin3 = afterRender: afterRender3
    afterRenderFoo = @spy()
    class Foo extends Backbone.View
      @mixin mixin2, mixin3
      afterRender: -> super and afterRenderFoo()
    window.Foo = Foo
    view = new Foo
    view.render()
    ok afterRender1.calledOnce, 'called mixin1 afterRender'
    ok afterRender2.calledOnce, 'called mixin2 afterRender'
    ok afterRender3.calledOnce, 'called mixin3 afterRender'
    ok afterRenderFoo.calledOnce, 'called foo afterRender'

    # order of mixing in shouldn't matter
    afterRender4 = @spy()
    afterRender5 = @spy()
    afterRender6 = @spy()
    mixin4 = afterRender: afterRender4
    mixin5 = mixing {}, mixin4, afterRender: afterRender5
    mixin6 = afterRender: afterRender6
    afterRenderBar = @spy()
    class Bar extends Backbone.View
      @mixin mixin6, mixin5
      afterRender: -> super and afterRenderBar()
    window.Bar = Bar
    bar = new Bar
    bar.render()
    ok afterRender4.calledOnce, 'called mixin4 afterRender'
    ok afterRender5.calledOnce, 'called mixin5 afterRender'
    ok afterRender6.calledOnce, 'called mixin6 afterRender'
    ok afterRenderBar.calledOnce, 'called bar afterRender'
