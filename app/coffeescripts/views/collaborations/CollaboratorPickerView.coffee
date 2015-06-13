#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'i18n!collaborations'
  'jquery'
  'Backbone'
  'compiled/views/collaborations/ListView'
  'compiled/views/collaborations/MemberListView'
  'jst/collaborations/CollaboratorPicker'
], (I18n, $, {View}, ListView, MemberListView, widgetTemplate) ->

  class CollaboratorPickerView extends View
    template: widgetTemplate

    events:
      'change .filters input': 'filterList'
      'focus .filters input': 'focusRadioGroup'
      'blur .filters input': 'blurRadioGroup'

    fetchOptions:
      data:
        per_page: 50

    initialize: ->
      super
      @cacheElements()
      @createLists()
      @attachEvents()
      @includeGroups = !window.location.pathname.match(/groups/)

    # Internal: Store references to DOM elements to avoid multiple lookups.
    #
    # Returns nothing.
    cacheElements: ->
      @$template   = $(@template(id: @options.id or 'new'))
      @$userList   = @$template.find('.available-users')
      @$groupList  = @$template.find('.available-groups')
      @$memberList = @$template.find('.members-list-wrapper')
      @$listFilter = @$template.find('.filters')

    # Internal: Attach events to child views.
    #
    # Returns nothing.
    attachEvents: ->
      @groupList.on('collection:remove',  @memberList.collection.add.bind(@memberList.collection))
      @userList.on('collection:remove',   @memberList.collection.add.bind(@memberList.collection))
      @memberList.on('collection:remove', @deselectCollaborator)
      @memberList.on('collection:reset',  @updateListFilters)

    # Internal: Create list sub-views.
    #
    # Returns nothing.
    createLists: ->
      currentUser = ENV.current_user_id && String(ENV.current_user_id)
      @userList   = new ListView
        currentUser: currentUser
        el: @$userList
        fetchOptions: @fetchOptions
        type: 'user'
      @groupList  = new ListView
        el: @$groupList
        fetchOptions: @fetchOptions
        type: 'group'
      @memberList = new MemberListView
        currentUser: currentUser
        el: @$memberList

    # Internal: Trigger initial fetch actions on each collection.
    #
    # Returns nothing.
    fetchCollaborators: ->
      @userList.collection.fetch(@fetchOptions)
      @groupList.collection.fetch(@fetchOptions) if @includeGroups
      if @options.edit
        @memberList.collection.url = "/api/v1/collaborations/#{@options.id}/members"
        @memberList.currentXHR = @memberList.collection.fetch(@fetchOptions)

    render: ->
      @$el.append(@$template)
      @fetchCollaborators()
      if @includeGroups then @$listFilter.buttonset() else @$listFilter.hide()
      this

    # Internal: Filter available collaborators.
    #
    # e - Event object.
    #
    # Returns nothing.
    filterList: (e) ->
      el = $(e.currentTarget).val()
      @$el.find('.available-lists ul').hide()
      @$el.find(".#{el}").show()

    focusRadioGroup: (e) ->
      $(e.currentTarget).parent().addClass("radio-group-outline")

    blurRadioGroup: (e) ->
      $(e.currentTarget).parent().removeClass("radio-group-outline")

    # Internal: Remove a collaborator and return them to their original list.
    #
    # collaborator - The model being removed from the collaborators list.
    #
    # Returns nothing.
    deselectCollaborator: (collaborator) =>
      list = if collaborator.modelType is 'user' then @userList else @groupList
      list.removeFromFilter(collaborator)
      list.collection.add(collaborator)

    # Internal: Pass filter updates to the right collection.
    #
    # type   - The string type of the collection (e.g. 'user' or 'group').
    # models - An array of models to update the filter with.
    #
    # Returns nothing.
    updateListFilters: (type, models) =>
      list = if type is 'user' then @userList else @groupList
      list.updateFilter(models)

