define [
  'jquery'
  'timezone'
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jst/wiki/WikiPage'
  'compiled/views/StickyHeaderMixin'
  'compiled/views/wiki/WikiPageDeleteDialog'
  'compiled/views/wiki/WikiPageReloadView'
  'compiled/views/PublishButtonView'
  'i18n!pages'
  'str/htmlEscape'
  'prerequisites_lookup'
  'content_locks'
], ($, tz, _, Backbone, splitAssetString, template, StickyHeaderMixin, WikiPageDeleteDialog, WikiPageReloadView, PublishButtonView, I18n, htmlEscape) ->

  class WikiPageView extends Backbone.View

    @mixin StickyHeaderMixin

    template: template

    els:
      '.publish-button': '$publishButton'
      '.header-bar-outer-container': '$headerBarOuterContainer'
      '.page-changed-alert': '$pageChangedAlert'

    events:
      'click .delete_page': 'deleteWikiPage'

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
      @model.on 'change', => @render()
      super
      @WIKI_RIGHTS ||= {}
      @PAGE_RIGHTS ||= {}

    render: ->
      # detach elements to preserve data/events
      @publishButtonView?.$el.detach()
      @$sequenceFooter?.detach()

      super

      if @model.get('locked_for_user')
        lock_info = @model.get('lock_info')
        $(".lock_explanation").html(htmlEscape(INST.lockExplanation(lock_info, 'page')))
        if lock_info.context_module && lock_info.context_module.id
          prerequisites_lookup = "#{ENV.MODULES_PATH}/#{lock_info.context_module.id}/prerequisites/wiki_page_#{@model.get('page_id')}"
          $('<a id="module_prerequisites_lookup_link" style="display: none;">').attr('href', prerequisites_lookup).appendTo($(".lock_explanation"))
          INST.lookupPrerequisites()

      # attach/re-attach the publish button
      unless @publishButtonView
        @publishButtonView = new PublishButtonView model: @model
        @model.view = @
      @publishButtonView.$el.appendTo(@$publishButton)
      @publishButtonView.render()

      # attach/re-attach the sequence footer (if this is a course, but not the home page)
      unless @$sequenceFooter || @course_home || !@course_id
        @$sequenceFooter ||= $('<div></div>').hide()
        @$sequenceFooter.moduleSequenceFooter(
          courseID: @course_id
          assetType: 'Page'
          assetID: @model.get('url')
          location: location
        )
      else
        @$sequenceFooter?.msfAnimation(false)
      @$sequenceFooter.appendTo(@$el) if @$sequenceFooter

    navigateToLinkAnchor: ->
      anchor_name = window.location.hash.replace(/^#/, "")
      if anchor_name.length
        $anchor = $("#wiki_page_show .user_content ##{anchor_name}")
        $anchor = $("#wiki_page_show .user_content a[name='#{anchor_name}']") unless $anchor.length
        if $anchor.length
          $('html, body').scrollTo($anchor)

    afterRender: ->
      super
      $(".header-bar-outer-container .header-bar-right").append($("#mark-as-done-checkbox"))
      @navigateToLinkAnchor()
      @reloadView = new WikiPageReloadView
        el: @$pageChangedAlert
        model: @model
        reloadMessage: I18n.t 'reload_viewing_page', 'This page has changed since you started viewing it. *Reload*', wrapper: '<a class="reload" href="#">$1</a>'
      @reloadView.on 'changed', =>
        @$headerBarOuterContainer.addClass('page-changed')
      @reloadView.on 'reload', =>
        @render()
      @reloadView.pollForChanges()

      $.publish('userContent/change')

    deleteWikiPage: (ev) ->
      ev?.preventDefault()
      return unless @model.get('deletable')

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        wiki_pages_path: @wiki_pages_path
      deleteDialog.open()

    toJSON: ->
      json = super
      json.modules_path = @modules_path
      json.wiki_pages_path = @wiki_pages_path
      json.wiki_page_edit_path = @wiki_page_edit_path
      json.wiki_page_history_path = @wiki_page_history_path
      json.course_home = @course_home
      json.course_title = @course_title
      json.CAN =
        VIEW_PAGES: !!@WIKI_RIGHTS.read
        PUBLISH: !!@WIKI_RIGHTS.manage && json.contextName == 'courses'
        VIEW_UNPUBLISHED: !!@WIKI_RIGHTS.manage || !!@WIKI_RIGHTS.view_unpublished_items
        UPDATE_CONTENT: !!@PAGE_RIGHTS.update || !!@PAGE_RIGHTS.update_content
        DELETE: !!@PAGE_RIGHTS.delete && !@course_home
        READ_REVISIONS: !!@PAGE_RIGHTS.read_revisions
      json.CAN.ACCESS_GEAR_MENU = json.CAN.DELETE || json.CAN.READ_REVISIONS
      json.CAN.VIEW_TOOLBAR = json.CAN.VIEW_PAGES || json.CAN.PUBLISH || json.CAN.UPDATE_CONTENT || json.CAN.ACCESS_GEAR_MENU

      json.lock_info = _.clone(json.lock_info) if json.lock_info
      if json.lock_info?.unlock_at
        json.lock_info.unlock_at = if tz.parse(json.lock_info.unlock_at) < new Date()
          null
        else
          $.datetimeString(json.lock_info.unlock_at)

      json.wiki_page_menu_tools = ENV.wiki_page_menu_tools
      _.each json.wiki_page_menu_tools, (tool) =>
        tool.url = tool.base_url + "&pages[]=#{@model.get("page_id")}"
      json

      json
