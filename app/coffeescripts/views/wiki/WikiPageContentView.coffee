define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/wiki/WikiPageContent'
], ($, _, Backbone, template) ->

  class WikiPageContentView extends Backbone.View
    tagName: 'article'
    className: 'show-content user_content'
    template: template

    @optionProperty 'modules_path'
    @optionProperty 'wiki_pages_path'
    @optionProperty 'wiki_page_edit_path'
    @optionProperty 'wiki_page_history_path'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'PAGE_RIGHTS'
    @optionProperty 'course_id'
    @optionProperty 'course_home'
    @optionProperty 'course_title'

    initialize: ->
      super
      @WIKI_RIGHTS ||= {}
      @PAGE_RIGHTS ||= {}
      @setModel(@model)

    afterRender: ->
      super
      $.publish('userContent/change')
      @trigger('render')

    setModel: (model) ->
      @model?.off null, null, @

      @model = model
      @model?.on 'change:title', (=> @render()), @
      @model?.on 'change:body', (=> @render()), @
      @render()

    toJSON: ->
      json = super
      json.modules_path = @modules_path
      json.wiki_pages_path = @wiki_pages_path
      json.wiki_page_edit_path = @wiki_page_edit_path
      json.wiki_page_history_path = @wiki_page_history_path
      json.course_home = @course_home
      json.course_title = @course_title
      json.CAN =
        VIEW_ALL_PAGES: !!@display_show_all_pages
        VIEW_PAGES: !!@WIKI_RIGHTS.read
        PUBLISH: !!@WIKI_RIGHTS.manage && json.contextName == 'courses'
        UPDATE_CONTENT: !!@PAGE_RIGHTS.update || !!@PAGE_RIGHTS.update_content
        DELETE: !!@PAGE_RIGHTS.delete && !@course_home
        READ_REVISIONS: !!@PAGE_RIGHTS.read_revisions
      json.CAN.ACCESS_GEAR_MENU = json.CAN.DELETE || json.CAN.READ_REVISIONS
      json.CAN.VIEW_TOOLBAR = json.CAN.VIEW_PAGES || json.CAN.PUBLISH || json.CAN.UPDATE_CONTENT || json.CAN.ACCESS_GEAR_MENU

      json.lock_info = _.clone(json.lock_info) if json.lock_info
      if json.lock_info?.unlock_at
        json.lock_info.unlock_at = if Date.parse(json.lock_info.unlock_at) < Date.now()
          null
        else
          $.datetimeString(json.lock_info.unlock_at)

      json
