#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/jquery/ModuleSequenceFooter'
], ($) ->

  default_course_url = "/api/v1/courses/42/module_item_sequence?asset_type=Assignment&asset_id=123&frame_external_urls=true"

  server_200_response = (data) ->
    [200, { "Content-Type": "application/json" }, JSON.stringify(data)]

  path_urls = {choose_url: 'chew-z', modules_url: 'mod.module.mod'}

  nextButton = (el) ->
    el.find('.module-sequence-footer-button--next').last()

  moduleData = (args = {}) ->
    Object.assign({
      items:
        [
          {
            current: { id: 768, module_id: 123, title: "A lonely page", type: "Page" },
            next: { id: 111, module_id: 123, title: "Project 33", type: "Assignment" },
            mastery_path: args['mastery_path']
          }
        ]
      modules:
        [
          { id: 123, name: "Module A" }
        ]
    }, args)

  QUnit.module 'ModuleSequenceFooter: init',
    setup: ->
      @$testEl = $('<div>')
      $('#fixtures').append @$testEl
      @stub($.fn.moduleSequenceFooter.MSFClass.prototype, 'fetch').returns({done: ->})

    teardown: ->
      @$testEl.remove()

  test 'returns jquery object of itself', ->
    jobj = @$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
    ok jobj instanceof $, 'returns an jquery instance of itself'

  test 'throws error if option is not set', ->
    throws (-> @$testEl.moduleSequenceFooter()), 'throws error when no options are passed in'

  test 'generatess a url based on the course_id', ->
    msf = new $.fn.moduleSequenceFooter.MSFClass({courseID: 42, assetType: 'Assignment', assetID: 42})
    equal msf.url, "/api/v1/courses/42/module_item_sequence", "generates a url based on the courseID"

  test 'attaches msfAnimation function', ->
    @$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
    notStrictEqual @$testEl.msfAnimation, undefined, 'msfAnimation function defined'

  test 'accepts animation option', ->
    $.fn.moduleSequenceFooter.MSFClass.prototype.fetch.restore()
    @stub($.fn.moduleSequenceFooter.MSFClass.prototype, 'fetch').callsFake ->
      this.success
        items: [
          prev: null
          current:
            id: 42
            module_id: 73
            title: 'A lonely page'
            type: 'Page'
          next:
            id: 43
            module_id: 73
            title: 'Another lonely page'
            type: 'Page'
        ]
        modules: [
          id: 73
          name: 'A lonely module'
        ]
      d = $.Deferred()
      d.resolve()
      d
    @$testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42, animation: false})
    equal @$testEl.find('.module-sequence-footer.no-animation').length, 1, 'no-animation applied to module-sequence-footer'
    equal @$testEl.find('.module-sequence-padding.no-animation').length, 1, 'no-animation applied to module-sequence-padding'

    @$testEl.msfAnimation(true)
    equal @$testEl.find('.module-sequence-footer:not(.no-animation)').length, 1, 'no-animation removed from module-sequence-footer'
    equal @$testEl.find('.module-sequence-padding:not(.no-animation)').length, 1, 'no-animation removed from module-sequence-padding'

  QUnit.module 'ModuleSequenceFooter: rendering',
    setup: ->
      @server = sinon.fakeServer.create()
      @$testEl = $('<div>')
      $('#fixtures').append @$testEl
    teardown: ->
      @server.restore()
      @$testEl.remove()

  nullButtonData = (args = {}) ->
    Object.assign({
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
            next: null,
            mastery_path: args['mastery_path']
          }
        ]

      modules:
        [
          {
            id: 123,
            name: "Module A",
          }
        ]
    }, args)

  test 'there is no button when next or prev data is null', ->
    @server.respondWith "GET", default_course_url, server_200_response(nullButtonData())
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
    @server.respondWith "GET", default_course_url, server_200_response(moduleTooltipData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok this.$testEl.find('a').first().data('html-tooltip-title').match('Module C'), "displays previous module tooltip"
    ok nextButton(this.$testEl).data('html-tooltip-title').match('Module B'), "displays next module tooltip"

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
    @server.respondWith "GET", default_course_url, server_200_response(itemTooltipData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok this.$testEl.find('a').first().data('html-tooltip-title').match('Project 1'), "displays previous item tooltip"
    ok nextButton(this.$testEl).data('html-tooltip-title').match('Project 33'), "displays next item tooltip"

  test 'if url has a module_item_id use that as the assetID and ModuleItem as the type instead', ->
    @server.respondWith "GET",
                        "/api/v1/courses/42/module_item_sequence?asset_type=ModuleItem&asset_id=999&frame_external_urls=true", server_200_response({})

    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123, location: {search:"?module_item_id=999" }})
    @server.respond()
    equal @server.requests[0].status, '200', 'Request was successful'

  test 'show gets called when rendering', ->
    @stub(@$testEl, 'show')
    @server.respondWith "GET", default_course_url, server_200_response(itemTooltipData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok @$testEl.show.called, 'show called'

  test 'resize event gets triggered', ->
    $(window).resize(() -> ok( true, "resize event triggered" ))
    @server.respondWith "GET", default_course_url, server_200_response(itemTooltipData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

  test 'provides correct tooltip for mastery path when awaiting choice', ->
    pathData = moduleData({mastery_path: Object.assign({awaiting_choice: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()
    btn = nextButton(this.$testEl)

    ok btn.data('html-tooltip-title').match('Choose the next mastery path'), "indicates a user needs to choose the next mastery path"
    ok btn.find('a').attr('href').match('chew-z'), "displays the correct link"

  test 'provides correct tooltip for mastery path when sequence is locked', ->
    pathData = moduleData({mastery_path: Object.assign({locked: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()
    btn = nextButton(this.$testEl)

    ok btn.data('html-tooltip-title').match('Next mastery path is currently locked'), "indicates there are locked mastery path items"
    ok btn.find('a').attr('href').match('mod.module.mod'), "displays the correct link"

  test 'provides correct tooltip for mastery path when processing', ->
    pathData = moduleData({mastery_path: Object.assign({still_processing: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()
    btn = nextButton(this.$testEl)

    ok btn.data('html-tooltip-title').match('Next mastery path is still processing'), "indicates path is processing"
    ok btn.find('a').attr('href').match('mod.module.mod'), "displays the correct link"

  test 'properly disables the next button when path locked and modules tab disabled', ->
    pathData = moduleData({mastery_path: Object.assign({locked: true, modules_tab_disabled: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok nextButton(this.$testEl).find('a').attr('disabled'), "disables the button"

  test 'properly disables the next button when path processing and modules tab disabled', ->
    pathData = moduleData({mastery_path: Object.assign({still_processing: true, modules_tab_disabled: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok nextButton(this.$testEl).find('a').attr('disabled'), "disables the button"

  test 'does not disables the next button when awaiting choice and modules tab disabled', ->
    pathData = moduleData({mastery_path: Object.assign({awaiting_choice: true, modules_tab_disabled: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok !nextButton(this.$testEl).find('a').attr('disabled'), "disables the button"

  test 'properly shows next button when no next items yet exist and paths are locked', ->
    pathData = nullButtonData({mastery_path: Object.assign({locked: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()
    btn = nextButton(this.$testEl)

    ok btn.data('html-tooltip-title').match('Next mastery path is currently locked'), "indicates there are locked mastery path items"
    ok btn.find('a').attr('href').match('mod.module.mod'), "displays the correct link"

  test 'properly shows next button when no next items yet exist and paths are processing', ->
    pathData = nullButtonData({mastery_path: Object.assign({still_processing: true}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()
    btn = nextButton(this.$testEl)

    ok btn.data('html-tooltip-title').match('Next mastery path is still processing'), "indicates path is processing"
    ok btn.find('a').attr('href').match('mod.module.mod'), "displays the correct link"

  test 'does not show next button when no next items exist and paths are unlocked', ->
    pathData = nullButtonData({mastery_path: Object.assign({still_processing: false}, path_urls)})
    @server.respondWith "GET", default_course_url, server_200_response(pathData)
    @$testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    @server.respond()

    ok @$testEl.find('a').length == 0, 'no buttons rendered'
