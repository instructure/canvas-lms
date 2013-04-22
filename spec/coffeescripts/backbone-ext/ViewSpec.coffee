define ['Backbone'], ({View}) ->

  module 'View'

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

  test 'template optionProperty', ->
    view = new View
      template: -> "hi"
    view.render()
    equal view.$el.html(), "hi",
      "template rendered with view as option"

  test 'child views', ->
    class ChildView extends View
      template: -> "hi"
    class ParentView extends View
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
    expected = foo: 'bar', cid: view.cid
    deepEqual expected, view.toJSON(), 'returns options'

    collection = new Backbone.Collection
    collection.toJSON = -> foo: 'bar'
    view = new Backbone.View {collection}
    expected = foo: 'bar', cid: view.cid
    deepEqual expected, view.toJSON(), 'uses @collection.toJSON'
    collection.present = -> foo: 'baz'
    expected = foo: 'baz', cid: view.cid
    deepEqual expected, view.toJSON(), 'uses @collection.present over toJSON'

    model = new Backbone.Model
    model.toJSON = -> foo: 'qux'
    view.model = model
    expected = foo: 'qux', cid: view.cid
    deepEqual expected, view.toJSON(), 'uses @model.toJSON over @collection'
    model.present = -> foo: 'quux'
    expected = foo: 'quux', cid: view.cid
    deepEqual expected, view.toJSON(), 'uses @model.present over toJSON'

  test 'View.mixin', 3, ->
    mixin1 =
      events: 'click .foo': 'foo'
      foo: -> ok true, 'called mixin1.foo'
    mixin2 =
      events: 'click .bar': 'bar'
      bar: -> ok true, 'called mixin2.bar'
    class SomeView extends View
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
      initialize: sinon.spy()
      attach: sinon.spy()
      afterRender: sinon.spy()
    mixin2 =
      initialize: sinon.spy()
      attach: sinon.spy()
      afterRender: sinon.spy()
    class SomeView extends View
      @mixin mixin1, mixin2
    view = new SomeView
    view.render()
    ok mixin1.initialize.calledOnce, 'called mixin1 initialize'
    ok mixin2.initialize.calledOnce, 'called mixin2 initialize'
    ok mixin1.afterRender.calledOnce, 'called mixin1 afterRender'
    ok mixin2.afterRender.calledOnce, 'called mixin2 afterRender'
    ok mixin1.attach.calledOnce, 'called mixin1 attach'
    ok mixin2.attach.calledOnce, 'called mixin2 attach'

