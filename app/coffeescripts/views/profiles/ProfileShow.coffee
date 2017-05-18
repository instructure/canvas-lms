#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'i18n!user_profile',
  'Backbone'
  'jquery'
  'jst/profiles/addLinkRow'
  'compiled/util/AvatarWidget'
  'jquery.instructure_forms'
], (I18n, Backbone, $, addLinkRow, AvatarWidget) ->

  class ProfileShow extends Backbone.View

    el: document.body

    events:
      'click [data-event]': 'handleDeclarativeClick'
      'submit #edit_profile_form': 'validateForm'
      'click .report_avatar_link': 'reportAvatarLink'

    attemptedDependencyLoads: 0

    initialize: ->
      super
      new AvatarWidget('.profile-link')

    reportAvatarLink: (e) ->
      e.preventDefault()
      return if !confirm(I18n.t("Are you sure you want to report this profile picture?"))
      link = $(e.currentTarget)
      $('.avatar').hide()
      $.ajaxJSON(link.attr('href'), "POST", {}, (data) =>
        $.flashMessage I18n.t("The profile picture has been reported")
      )

    handleDeclarativeClick: (event) ->
      event.preventDefault()
      $target = $ event.currentTarget
      method = $target.data 'event'
      @[method]? event, $target

    ##
    # first run initializes some stuff, then is reassigned
    # to a showEditForm
    editProfile: ->
      @initEdit()
      @editProfile = @showEditForm

    showEditForm: ->
      @$el.addClass('editing').removeClass('not-editing')
      elementToFocus = document.querySelector("#name_input") || document.querySelector("#profile_bio")
      elementToFocus.focus()

    initEdit: ->
      if @options.links?.length
        @addLinkField(null, null, title, url) for {title, url} in @options.links
      else
        @addLinkField()
        @addLinkField()

      @showEditForm()

    cancelEditProfile: ->
      @$el.addClass('not-editing').removeClass('editing')

    ##
    # Event handler that can also be called manually.
    # When called manually, it will focus the first input in the new row
    addLinkField: (event, $el, title = '', url = '') ->
      @$linkFields ?= @$ '#profile_link_fields'
      $row = $(addLinkRow({title: title, url: url}))
      @$linkFields.append $row

      # focus if called from the "add row" button
      if event?
        event.preventDefault()
        $row.find('input:first').focus()

    removeLinkRow: (event, $el) ->
      $parentRow = $el.parents('tr')
      $toFocus = $parentRow.prev().find('.remove_link_row')
      if $toFocus.length == 0
        $toFocus = $('#profile_bio')

      $parentRow.remove()
      $toFocus.focus()

    validateForm: (event) ->
      validations =
        property_validations:
          'user_profile[title]': (value) ->
            if value && value.length > 255
              return I18n.t("profile_title_too_long", "Title is too long")
      if !$(event.target).validateForm(validations)
        event.preventDefault()
