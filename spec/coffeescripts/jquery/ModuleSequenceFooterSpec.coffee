define [
  'jquery'
  'compiled/jquery/ModuleSequenceFooter'
], ($) ->
  module 'ModuleSequenceFooter: init',
    setup: ->
      @$testEl = $('<div>')
      $('#fixtures').append @$testEl
      sinon.stub $.fn.moduleSequenceFooter.MSFClass.prototype, 'fetch', -> {done: ->}

    teardown: -> 
      @$testEl.remove()
      $.fn.moduleSequenceFooter.MSFClass.prototype.fetch.restore()

  test 'returns jquery object of itself', ->
    jobj = @$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
    ok jobj instanceof $, 'returns an jquery instance of itself'

  test 'throws error if option is not set', ->
    throws (-> @$testEl.moduleSequenceFooter()), 'throws error when no options are passed in'

  test 'generatess a url based on the course_id', ->
    msf = new $.fn.moduleSequenceFooter.MSFClass({courseID: 42, assetType: 'Assignment', assetID: 42})
    equal msf.url, "/api/v1/courses/42/module_item_sequence", "generates a url based on the courseID"

  module 'ModuleSequenceFooter: rendering',
    setup: -> 
      @server = sinon.fakeServer.create()
      @$testEl = $('<div>')
      $('#fixtures').append @$testEl
    teardown: -> 
      @server.restore()
      @$testEl.remove()

  nullButtonData = 
     {
       items:
         [
           {
             prev: null,
             current:
               {
                 id: 768,
                 module_id: 123,
                 title: "A lonely page",
                 type: "Page",
               }
             next: null
           }
         ]

       modules:
         [
           {
             id: 123,
             name: "Module A",
           }
         ]
     }

  test 'there is no button when next or prev data is null', ->
    @server.respondWith "GET", 
                        "/api/v1/courses/42/module_item_sequence?asset_type=Assignment&asset_id=123",
                        [
                          200, { "Content-Type": "application/json" }, JSON.stringify(nullButtonData)
                        ]
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok @$testEl.find('a').length == 0, 'no buttons rendered'

  moduleTooltipData = 
     {
       items:
         [
           {
             prev:
               {
                 id: 769,
                 module_id: 111,
                 title: "Project 1",
                 type: "Assignment",
               }
             current:
               {
                 id: 768,
                 module_id: 123,
                 title: "A lonely page",
                 type: "Page",
               }
             next:
               {
                 id: 111,
                 module_id: 666,
                 title: "Project 33",
                 type: "Assignment",
               }
           }
         ]

       modules:
         [
           {
             id: 123,
             name: "Module A",
           }
           {
             id: 666,
             name: "Module B",
           }
           {
             id: 111,
             name: "Module C",
           }
         ]
     }
  test 'buttons show modules tooltip when current module id != next or prev module id', ->
    @server.respondWith "GET", 
                        "/api/v1/courses/42/module_item_sequence?asset_type=Assignment&asset_id=123",
                        [
                          200, { "Content-Type": "application/json" }, JSON.stringify(moduleTooltipData)
                        ]
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok this.$testEl.find('a').first().attr('title').match('Module C'), "displays previous module tooltip"
    ok this.$testEl.find('a').last().attr('title').match('Module B'), "displays next module tooltip"

  itemTooltipData = 
     {
       items:
         [
           {
             prev:
               {
                 id: 769,
                 module_id: 123,
                 title: "Project 1",
                 type: "Assignment",
               }
             current:
               {
                 id: 768,
                 module_id: 123,
                 title: "A lonely page",
                 type: "Page",
               }
             next:
               {
                 id: 111,
                 module_id: 123,
                 title: "Project 33",
                 type: "Assignment",
               }
           }
         ]

       modules:
         [
           {
             id: 123,
             name: "Module A",
           }
         ]
     }

  test 'buttons show item tooltip when current module id == next or prev module id', ->
    @server.respondWith "GET", 
                        "/api/v1/courses/42/module_item_sequence?asset_type=Assignment&asset_id=123",
                        [
                          200, { "Content-Type": "application/json" }, JSON.stringify(itemTooltipData)
                        ]
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok this.$testEl.find('a').first().attr('title').match('Project 1'), "displays previous item tooltip"
    ok this.$testEl.find('a').last().attr('title').match('Project 33'), "displays next item tooltip"

  test 'if url has a module_item_id use that as the assetID and ModuleItem as the type instead', ->
    @server.respondWith "GET", 
                        "/api/v1/courses/42/module_item_sequence?asset_type=ModuleItem&asset_id=999",
                        [
                          200, { "Content-Type": "application/json" }, JSON.stringify({})
                        ]
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123, location: {search:"?module_item_id=999" }})
    @server.respond()
    equal @server.requests[0].status, '200', 'Request was successful'

  test 'show gets called when rendering', ->
    @sandbox.stub(@$testEl, 'show')
    @server.respondWith "GET",
                        "/api/v1/courses/42/module_item_sequence?asset_type=Assignment&asset_id=123",
                        [
                          200, { "Content-Type": "application/json" }, JSON.stringify(itemTooltipData)
                        ]
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok @$testEl.show.called, 'show called'
