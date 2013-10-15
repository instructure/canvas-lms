# Based on https://raw.github.com/ebryn/ember-model/master/packages/ember-model/lib/rest_adapter.js

define [
  'ember'
  './parse_page_links'
], (Ember,parsePageLinks) ->
  get = Ember.get

  Ember.RecordArray.reopen
    nextPage: ->
      return unless this.get 'links.next'
      model = this.get 'model'
      model.adapter.findNextPage model, this
    pushObjects: (data) ->
      @_super this.materializeData(this.get('model'), data)
      this.notifyLoaded();
    findFirstPage: (url) ->
      alert 'findFirstPage'
    firstNextPage: () ->
      alert 'findNextPage'

  Ember.Adapter.extend
    find: (record, id) ->
      url = @buildURL(record.constructor, id)
      self = this
      @ajax(url).then ({data}) ->
        self.didFind record, id, data
        record

    didFind: (record, id, data) ->
      rootKey = get(record.constructor, 'rootKey')
      dataToLoad = (if rootKey then data[rootKey] else data)
      record.load id, dataToLoad

    findAll: (klass, records) ->
      url = @buildURL(klass)
      self = this
      @ajax(url).then ({data}) ->
        self.didFindAll klass, records, data
        records

    didFindAll: (klass, records, data) ->
      collectionKey = get(klass, 'collectionKey')
      dataToLoad = (if collectionKey then data[collectionKey] else data)
      records.load klass, dataToLoad

    findQuery: (klass, records, params) ->
      url = @buildURL(klass)
      self = this
      @ajax(url, params).then ({data, textStatus, jqXHR}) ->
        self.didFindQuery klass, records, params, data, jqXHR
        records

    didFindQuery: (klass, records, params, data, jqXHR) ->
      collectionKey = get(klass, 'collectionKey')
      records.set 'links', parsePageLinks jqXHR
      dataToLoad = (if collectionKey then data[collectionKey] else data)
      records.load klass, dataToLoad
      records

    findNextPage: (klass, records, params) ->
      url = records.get 'links.next'
      return if not url
      records.set 'links.next', null
      self = this
      @ajax(url, params).then ({data, textStatus, jqXHR}) ->
        self.didFindNextPage klass, records, params, data, jqXHR
        records

    didFindNextPage: (klass, records, params, data, jqXHR) ->
      records.set 'links', parsePageLinks jqXHR
      records.pushObjects data
      records.trigger 'didAddPage'
      records

    createRecord: (record) ->
      url = @buildURL(record.constructor)
      self = this
      @ajax(url, record.toJSON(), 'POST').then ({data}) ->
        self.didCreateRecord record, data
        record

    didCreateRecord: (record, data) ->
      rootKey = get(record.constructor, 'rootKey')
      primaryKey = get(record.constructor, 'primaryKey')
      dataToLoad = (if rootKey then data[rootKey] else data)
      record.load dataToLoad[primaryKey], dataToLoad
      record.didCreateRecord()

    saveRecord: (record) ->
      primaryKey = get(record.constructor, 'primaryKey')
      url = @buildURL(record.constructor, get(record, primaryKey))
      self = this
      @ajax(url, record.toJSON(), 'PUT').then ({data}) -> # TODO: Some APIs may or may not return data
        self.didSaveRecord record, data
        record

    didSaveRecord: (record, data) ->
      record.didSaveRecord()

    deleteRecord: (record) ->
      primaryKey = get(record.constructor, 'primaryKey')
      url = @buildURL(record.constructor, get(record, primaryKey))
      self = this
      @ajax(url, record.toJSON(), 'DELETE').then ({data}) -> # TODO: Some APIs may or may not return data
        self.didDeleteRecord record, data

    didDeleteRecord: (record, data) ->
      record.didDeleteRecord()

    ajax: (url, params, method) ->
      @_ajax url, params, method or 'GET'

    buildURL: (klass, id) ->
      urlRoot = get(klass, 'url')
      throw new Error('Ember.RESTAdapter requires a `url` property to be specified')  unless urlRoot
      unless Ember.isEmpty(id)
        urlRoot + '/' + id
      else
        urlRoot

    ajaxSettings: (url, method) ->
      url: url
      type: method
      dataType: 'json'

    _ajax: (url, params, method) ->
      settings = @ajaxSettings(url, method)
      new Ember.RSVP.Promise((resolve, reject) ->
        if params
          if method is 'GET'
            settings.data = params
          else
            # settings.contentType = 'application/json; charset=utf-8'
            settings.data = JSON.stringify(params)
        settings.success = (data, textStatus, jqXHR) ->
          resolve {data, textStatus, jqXHR}
          # Ember.run null, resolve, {data, textStatus, jqXHR}

        settings.error = (jqXHR, textStatus, errorThrown) ->
          console.log 'Error when fetching records', {jqXHR, textStatus, errorThrown}
          # https://github.com/ebryn/ember-model/issues/202
          # jqXHR.then = null if jqXHR
          # Ember.run null, reject, jqXHR
        Ember.$.ajax settings
      )