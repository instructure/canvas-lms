#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jsx/shared/rce/serviceRCELoader'
  'jsx/shared/jwt',
  'helpers/editorUtils'
  'helpers/fakeENV'
  'helpers/fixtures'
], ($, RCELoader, jwt, editorUtils, fakeENV, fixtures) ->
  QUnit.module 'loadRCE',
    setup: ->
      @originalTinymce = window.tinymce
      @originalTinyMCE = window.tinyMCE
      fakeENV.setup()
      ENV.RICH_CONTENT_APP_HOST = 'app-host'

    teardown: ->
      # until canvas and canvas-rce are on the same version, restore globals to
      # the canvas version of tinymce
      window.tinymce = @originalTinymce
      window.tinyMCE = @originalTinyMCE
      fakeENV.teardown()
      editorUtils.resetRCE()

  # loading RCE

  test 'caches the response of get_module when called', (assert) ->
    done = assert.async()
    RCELoader.RCE = null
    RCELoader.loadRCE (module) =>
      equal RCELoader.RCE, module
      done()

  test 'loads event listeners on first load', (assert) ->
    done = assert.async()
    @stub(RCELoader, 'loadEventListeners')
    RCELoader.RCE = null
    RCELoader.loadRCE () =>
      ok RCELoader.loadEventListeners.called
      done()

  test 'does not load event listeners once loaded', (assert) ->
    done = assert.async()
    @stub(RCELoader, 'loadEventListeners')
    RCELoader.RCE = {}
    RCELoader.loadRCE () =>
      ok !RCELoader.loadEventListeners.called
      done()

  test 'handles callbacks once module is loaded', (assert) ->
    done = assert.async()
    RCELoader.loadRCE(()->)
    RCELoader.loadRCE (module) =>
      ok(module.renderIntoDiv)
      done()

  QUnit.module 'loadOnTarget',
    setup: ->
      fixtures.setup()
      @$div = fixtures.create('<div><textarea id="theTarget" name="elementName" /></div>')
      @$textarea = fixtures.find('#theTarget')
      @editor = {}
      @rce = { renderIntoDiv: sinon.stub().callsArgWith(2, @editor) }
      sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, @rce)

    teardown: ->
      fixtures.teardown()
      RCELoader.loadRCE.restore()

  # target finding

  test 'finds a target textarea if a textarea is passed in', ->
    equal RCELoader.getTargetTextarea(@$textarea), @$textarea.get(0)

  test 'finds a target textarea if a normal div is passed in', ->
    equal RCELoader.getTargetTextarea(@$div), @$textarea.get(0)

  test 'returns the textareas parent as the renderingTarget when no custom function given', ->
    equal RCELoader.getRenderingTarget(@$textarea.get(0)), @$div.get(0)

  test 'returned parent has class `ic-RichContentEditor`', ->
    target = RCELoader.getRenderingTarget(@$textarea.get(0))
    ok $(target).hasClass('ic-RichContentEditor')

  test 'uses a custom get target function if given', ->
    customFn = -> "someCustomTarget"
    RCELoader.loadOnTarget(@$textarea, {getRenderingTarget: customFn}, ()->)
    ok @rce.renderIntoDiv.calledWith("someCustomTarget")

  # propsForRCE construction

  test 'extracts content from the target', ->
    @$textarea.val('some text here')
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.defaultContent, "some text here"

  test 'falls back to defaultContent if target has no content', ->
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.defaultContent, "default text"

  test 'passes the textarea height into tinyOptions', ->
    taHeight = "123"
    textarea = { offsetHeight: taHeight }
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(textarea, opts)
    equal opts.tinyOptions.height, taHeight

  test 'adds the elements name attribute to mirroredAttrs', ->
    opts = {defaultContent: "default text"}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.mirroredAttrs.name, "elementName"

  test 'adds onFocus to props', ->
    opts = {onFocus: ->}
    props = RCELoader.createRCEProps(@$textarea.get(0), opts)
    equal props.onFocus, opts.onFocus

  test 'renders with rce', ->
    RCELoader.loadOnTarget(@$div, {}, ()->)
    ok @rce.renderIntoDiv.calledWith(@$div.get(0))

  test 'yields editor to callback', ->
    cb = sinon.spy()
    RCELoader.loadOnTarget(@$div, {}, cb)
    ok cb.calledWith(@$textarea.get(0), @editor)

  test 'ensures yielded editor has call and focus methods', ->
    cb = sinon.spy()
    RCELoader.loadOnTarget(@$div, {}, cb)
    equal typeof @editor.call, 'function'
    equal typeof @editor.focus, 'function'

  QUnit.module 'loadSidebarOnTarget',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_APP_HOST = 'http://rce.host'
      ENV.RICH_CONTENT_CAN_UPLOAD_FILES = true
      ENV.context_asset_string = 'courses_1'
      fixtures.setup()
      @$div = fixtures.create('<div />')
      @sidebar = {}
      @rce = { renderSidebarIntoDiv: sinon.stub().callsArgWith(2, @sidebar) }
      sinon.stub(RCELoader, 'loadRCE').callsArgWith(0, @rce)
      @refreshToken = sinon.spy()
      @stub(jwt, 'refreshFn').returns(@refreshToken)

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      RCELoader.loadRCE.restore()

  test 'passes host and context from ENV as props to sidebar', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    ok @rce.renderSidebarIntoDiv.called
    props = @rce.renderSidebarIntoDiv.args[0][1]
    equal props.host, 'http://rce.host'
    equal props.contextType, 'courses'
    equal props.contextId, '1'

  test 'yields sidebar to callback', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    ok cb.calledWith(@sidebar)

  test 'ensures yielded sidebar has show and hide methods', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    equal typeof @sidebar.show, 'function'
    equal typeof @sidebar.hide, 'function'

  test 'provides a callback for loading a new jwt', ->
    cb = sinon.spy()
    RCELoader.loadSidebarOnTarget(@$div, cb)
    ok @rce.renderSidebarIntoDiv.called
    props = @rce.renderSidebarIntoDiv.args[0][1]
    ok jwt.refreshFn.calledWith(props.jwt)
    equal(props.refreshToken, @refreshToken)

  test 'passes brand config json url', ->
    ENV.active_brand_config_json_url = {}
    RCELoader.loadSidebarOnTarget(@$div, ->)
    props = @rce.renderSidebarIntoDiv.args[0][1]
    equal props.themeUrl, ENV.active_brand_config_json_url
