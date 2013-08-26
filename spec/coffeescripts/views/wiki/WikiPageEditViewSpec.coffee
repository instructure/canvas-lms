define [
  'jquery'
  'compiled/views/wiki/WikiPageEditView'
  'wikiSidebar'
], ($, WikiPageEditView, wikiSidebar) ->

  module 'WikiPageEditView:Init',
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


  module 'WikiPageEditView:Validate'

  test 'validation of the title is only performed if the title is present', ->
    view = new WikiPageEditView

    errors = view.validateFormData wiki_page: {body: 'blah'}
    strictEqual errors['wiki_page[title]'], undefined, 'no error when title is omitted'

    errors = view.validateFormData wiki_page: {title: 'blah', body: 'blah'}
    strictEqual errors['wiki_page[title]'], undefined, 'no error when title is present'

    errors = view.validateFormData wiki_page: {title: '', body: 'blah'}
    ok errors['wiki_page[title]'], 'error when title is present, but blank'
    ok errors['wiki_page[title]'][0].message, 'error message when title is present, but blank'


  module 'WikiPageEditView:JSON'

  test 'WIKI_RIGHTS', ->
    view = new WikiPageEditView
      WIKI_RIGHTS:
        good: true
    strictEqual view.toJSON().WIKI_RIGHTS.good, true, 'WIKI_RIGHTS represented in toJSON'

  test 'PAGE_RIGHTS', ->
    view = new WikiPageEditView
      PAGE_RIGHTS:
        good: true
    strictEqual view.toJSON().PAGE_RIGHTS.good, true, 'PAGE_RIGHTS represented in toJSON'
