define [
  'ic-ajax'
  'ember'
  'ember-data'
  '../start_app'
  '../environment_setup'
  '../../mixins/queriable_model'
], (ajax, {run}, {Model}, startApp, env, QueriableModel) ->

  App = null
  subject = null

  module "QueriableModel",
    setup: ->
      App = startApp()
      App.reopen({
        SpecModel: Model.extend(QueriableModel, {}),
        SpecModelAdapter: App.ApplicationAdapter.extend({
          # use ic-ajax
          ajax: (url, method) ->
            ajax.request({ url: url, type: method })

          # use the model's "url" attribute if it's persistent
          buildURL: (type, id) ->
            return @_super(type, id) unless id

            this.container.lookup('store:main')
              .getById('specModel', id)
                .get('url')
        })
      })

      run ->
        container = App.__container__
        store = container.lookup 'store:main'
        subject = store.createRecord 'specModel', { id: 1 }

    teardown: ->
      run App, 'destroy'

  asyncTest '#reload: it uses the query parameters', ->
    ajax.defineFixture '/api/v1/courses/1/spec_models/1?page=1', textStatus: 'success', response: {
      id: 1,
      fruit: 'banana'
    }

    run ->
      url = '/api/v1/courses/1/spec_models/1'
      subject.set('url', url)
      svc = subject.reload({ 'page': 1 })
      svc.then ->
        ok true, "it appended ?page=1 to the url"

      svc.catch ->
        ok false, "it didn't append the query params"

      svc.finally ->
        start()

  asyncTest '#reload: it restores the original url', ->
    ajax.defineFixture '/api/v1/courses/1/spec_models/1?page=1', textStatus: 'success', response: {
      id: 1,
      fruit: 'banana'
    }

    run ->
      url = '/api/v1/courses/1/spec_models/1'
      subject.set('url', url)
      svc = subject.reload({ 'page': 1 })
      svc.then ->
        equal subject.get('url'), url, "it restores the URL after reloading"

      svc.catch ->
        ok false, "it didn't append the query params"

      svc.finally ->
        start()
