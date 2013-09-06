define [
  'ember'
  '../lib/parse_page_links'
  'jquery'
  'underscore'
], (Ember,parsePageLinks,$, _) ->
  # ModuleItem = Ember.Object.extend()

  Module = Ember.Object.extend()
  Module.url = '/api/v1/courses/' + window?.ENV?.COURSE_ID + '/modules?include%5B%5D=items&include%5B%5D=content_details&page=1&per_page=50'

  Module.reopen
    modulePrereqs: (->
      modules = Module.records.get('content')
      ids = this.get('prerequisite_module_ids')
      prereq_modules = _.filter modules, (module) ->
        if _.contains ids, module.get('id')
          return module
    ).property()

    prereqModuleCount: (->
      this.get('prerequisite_module_ids').length
    ).property()

    onePrereq: (->
      this.get('prerequisite_module_ids').length == 1
    ).property()

    moreThanOnePrereq: (->
      this.get('prerequisite_module_ids').length > 1
    ).property()

    prereqModuleName: (->
      this.get('modulePrereqs')[0].get('name')
    ).property()

    prereqModuleNames: (->
      names = _.map this.get('modulePrereqs'), (module) ->
        module.get('name')
      names.join(", ")
    ).property()

    loadNextPage: ->
      if @items.get('links').next
        @items.set 'loading', true
        Ember.$.getJSON @items.get('links').next, (data, textStatus, jqXHR) =>
          @items.set 'loading', false
          @items.pushObjects data
          @items.set 'links', parsePageLinks jqXHR
    items: (->
      items = []
      if not @items?.length and @items_count and @items_url?
        # @items.set 'loading', true
        Ember.$.getJSON @get('items_url') + '?include%5B%5D=content_details', (data, textStatus, jqXHR) =>
          items.pushObjects data
          items.set 'links', parsePageLinks jqXHR
          # @items.set 'loading', false
      @items = items
    ).property()

  Module.reopenClass
    records: Ember.ArrayProxy.create content: []
    findAll: ->
      Module.records.set 'loading', true
      Ember.$.ajax
        dataType: 'json'
        url: @url,
        success: (data, textStatus, jqXHR) =>
          records = data.map (record) -> record = Module.create record
          Module.records.pushObjects records
          Module.records.set 'loading', false
          Module.records.set 'links', parsePageLinks jqXHR
        error: (error) ->
          console.log 'error: ', error
      Module.records
    loadNextPage: ->
      url = Module.records.get('links.next')
      return unless url
      Module.records.set 'loading', true
      Module.records.set 'links.next', null
      Ember.$.getJSON url, (data, textStatus, jqXHR) =>
        records = data.map (record) -> record = Module.create record
        Module.records.pushObjects records
        Module.records.set 'loading', false
        Module.records.set 'links', parsePageLinks jqXHR
  Module
