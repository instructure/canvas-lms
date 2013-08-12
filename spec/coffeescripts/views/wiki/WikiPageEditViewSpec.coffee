define [
  'jquery'
  'compiled/views/wiki/WikiPageEditView'
  'wikiSidebar'
], ($, WikiPageEditView, wikiSidebar) ->
  module 'WikiPageEdit:Init',
    setup: ->
      @initStub = sinon.stub(wikiSidebar, 'init')
      @scrollSidebarStub = sinon.stub($, 'scrollSidebar')
      @attachWikiEditorStub = sinon.stub(wikiSidebar, 'attachToEditor')
      @attachWikiEditorStub.returns(show: sinon.stub())
    teardown: ->
      @scrollSidebarStub.restore()
      @initStub.restore()
      @attachWikiEditorStub.restore()

  test 'init wiki sidebar during render', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @initStub.calledOnce, 'Called wikiSidebar init once'

  test 'scroll sidebar during render', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @scrollSidebarStub.calledOnce, 'Called scrollSidebar once'

  test 'wiki body gets attached to the wikisidebar', ->
    wikiPageEditView = new WikiPageEditView
    wikiPageEditView.render()
    ok @attachWikiEditorStub.calledOnce, 'Attached wikisidebar to body'

