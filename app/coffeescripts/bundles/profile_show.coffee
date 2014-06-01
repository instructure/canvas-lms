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

require [
  'i18n!user_profile',
  'Backbone'
  'jquery'
  'str/htmlEscape'
  'compiled/util/AvatarWidget'
  'compiled/tinymce'
  'jquery.instructure_forms'
  'tinymce.editor_box'
], (I18n, {View}, $, htmlEscape, AvatarWidget) ->

  class ProfileShow extends View

    el: document.body

    events:
      'click [data-event]': 'handleDeclarativeClick'
      'submit #edit_profile_form': 'validateForm'

    attemptedDependencyLoads: 0

    initialize: ->
      super
      new AvatarWidget('.profile-link')

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
      @$('.profile_links').removeClass('span6')

    initEdit: ->
      if @options.links?.length
        @addLinkField(null, null, title, url) for {title, url} in @options.links
      else
        @addLinkField()
        @addLinkField()

      # setTimeout so tiny has some width to read
      #setTimeout -> @$('#profile_bio').editorBox()
      @showEditForm()

    cancelEditProfile: ->
      @$el.addClass('not-editing').removeClass('editing')
      @$('.profile_links').addClass('span6')

    ##
    # Event handler that can also be called manually.
    # When called manually, it will focus the first input in the new row
    addLinkField: (event, $el, title = '', url = '') ->
      @$linkFields ?= @$ '#profile_link_fields'
      $row = $ """
        <tr>
          <td><input type="text" maxlength="255" name="link_titles[]" value="#{htmlEscape title}"></td>
          <td>→</td>
          <td><input type="text" name="link_urls[]" value="#{htmlEscape url}"></td>
          <td><a href="#" data-event="removeLinkRow"><i class="icon-end"></i></a></td>
        </tr>
      """
      @$linkFields.append $row

      # focus if called from the "add row" button
      if event?
        event.preventDefault()
        $row.find('input:first').focus()

    removeLinkRow: (event, $el) ->
      $el.parents('tr').remove()

    validateForm: (event) ->
      validations =
        property_validations:
          'user_profile[title]': (value) ->
            if value && value.length > 255
              return I18n.t("profile_title_too_long", "Title is too long")
      if !$(event.target).validateForm(validations)
        event.preventDefault()

  new ProfileShow ENV.PROFILE

