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
  'Backbone'
  'i18n!pages'
  './WikiPageIndexEditDialog'
  './WikiPageDeleteDialog'
  '../PublishIconView'
  '../LockIconView'
  'jst/wiki/WikiPageIndexItem'
  '../../jquery/redirectClickTo'
], (Backbone, I18n, WikiPageIndexEditDialog, WikiPageDeleteDialog, PublishIconView, LockIconView, template) ->

  class WikiPageIndexItemView extends Backbone.View
    template: template
    tagName: 'tr'
    className: 'clickable'
    attributes:
      role: 'row'
    els:
      '.wiki-page-link': '$wikiPageLink'
      '.publish-cell': '$publishCell'
      '.master-content-lock-cell': '$lockCell'
    events:
      'click a.al-trigger': 'settingsMenu'
      'click .edit-menu-item': 'editPage'
      'click .delete-menu-item': 'deletePage'
      'click .use-as-front-page-menu-item': 'useAsFrontPage'
      'click .unset-as-front-page-menu-item': 'unsetAsFrontPage'
      'click .duplicate-wiki-page': 'duplicateWikiPage'

    @optionProperty 'indexView'
    @optionProperty 'collection'
    @optionProperty 'WIKI_RIGHTS'
    @optionProperty 'contextName'

    initialize: ->
      super
      @WIKI_RIGHTS ||= {}
      @model.set('unpublishable', true)
      @model.on 'change', => @render()

    toJSON: ->
      json = super
      json.CAN =
        MANAGE: !!@WIKI_RIGHTS.manage
        PUBLISH: !!@WIKI_RIGHTS.manage && @contextName == 'courses'
        # TODO: Consider allowing duplicating pages in other contexts
        DUPLICATE: !!@WIKI_RIGHTS.manage && @contextName == 'courses'

      if json.is_master_course_child_content && json.restricted_by_master_course
        json.cannot_delete_by_master_course = true
        json.cannot_edit_by_master_course = json.master_course_restrictions.content

      json.wiki_page_menu_tools = ENV.wiki_page_menu_tools || []
      json.wiki_page_menu_tools.forEach (tool) =>
        tool.url = tool.base_url + "&pages[]=#{@model.get("page_id")}"
      json

    render: ->
      # detach the icons to preserve data/events
      @publishIconView?.$el.detach()
      @lockIconView?.$el.detach()

      super

      # attach/re-attach the icons
      unless @publishIconView
        @publishIconView = new PublishIconView(
          model: @model,
          title: @model.get('title')
        )
        @model.view = @
      @publishIconView.$el.appendTo(@$publishCell)
      @publishIconView.render()

      unless @lockIconView
        @lockIconView = new LockIconView({
          model: @model,
          unlockedText: I18n.t("%{name} is unlocked. Click to lock.", name: @model.get('title')),
          lockedText: I18n.t("%{name} is locked. Click to unlock.", name: @model.get('title')),
          course_id: ENV.COURSE_ID
          content_id: @model.get('page_id'),
          content_type: 'wiki_page'
        })
        @model.view = @
      @lockIconView.$el.appendTo(@$lockCell)
      @lockIconView.render()

    afterRender: ->
      @$el.find('td:first').redirectClickTo(@$wikiPageLink)

    settingsMenu: (ev) ->
      ev?.preventDefault()

    editPage: (ev = {}) ->
      ev.preventDefault()

      $curCog = $(ev.target).parents('td').children().find('.al-trigger')

      editDialog = new WikiPageIndexEditDialog
        model: @model
        returnFocusTo: $curCog
      editDialog.open()

      indexView = @indexView
      collection = @collection
      editDialog.on 'success', ->
        indexView.focusAfterRenderSelector = 'a#' + @model.get('page_id') + '.al-trigger';
        indexView.currentSortField = null
        indexView.renderSortHeaders()

        collection.fetch page: 'current'

    deletePage: (ev = {}) ->
      ev.preventDefault()

      return unless @model.get('deletable')

      $curCog = $(ev.target).parents('td').children().find('.al-trigger')
      $allCogs = $('.collectionViewItems').children().find('.al-trigger')
      curIndex = $allCogs.index($curCog)
      newIndex = curIndex - 1
      if (newIndex < 0)
        # We were at the top, or there wasn't another page item cog
        $focusOnDelete = $('.new_page')
      else
        $allTitles = $('.collectionViewItems').children().find('.wiki-page-link')
        $focusOnDelete = $allTitles[newIndex]

      deleteDialog = new WikiPageDeleteDialog
        model: @model
        focusOnCancel: $curCog
        focusOnDelete: $focusOnDelete
      deleteDialog.open()

    duplicateWikiPage: (ev) ->
      ev?.preventDefault()
      collection = @collection
      model = @model

      handleResponse = (response) ->
        placeToAdd = collection.indexOf(model) + 1
        collection.add(response, { at: placeToAdd })
        $("#wiki_page_index_item_title_#{response.page_id}").focus()

      @model.duplicate(ENV.COURSE_ID, handleResponse)
      return

    unsetAsFrontPage: (ev) ->
      ev?.preventDefault()

      if (ev?.target)
        $curCog = $(ev.target).parents('td').children().find('.al-trigger')
        $allCogs =  $('.collectionViewItems').children().find('.al-trigger')
        curIndex = $allCogs.index($curCog)

      @model.unsetFrontPage ->
        # Here's the aforementioned magic and index stuff
        if (curIndex?)
          cogs = $('.collectionViewItems').children().find('.al-trigger')
          $(cogs[curIndex]).focus()

    useAsFrontPage: (ev) ->
      ev?.preventDefault()
      return unless @model.get('published')
      # This bit of magic has to happen this way because the $curCog
      # isn't valid after the re-render occurs... so we use the index and
      # re-collect the cogs afterwards.
      if (ev?.target)
        $curCog = $(ev.target).parents('td').find('.al-trigger')
        $allCogs =  $('.collectionViewItems').find('.al-trigger')
        curIndex = $allCogs.index($curCog)

      @model.setFrontPage ->
        # Here's the aforementioned magic and index stuff
        if (curIndex?)
          cogs = $('.collectionViewItems').find('.al-trigger')
          $(cogs[curIndex]).focus()
