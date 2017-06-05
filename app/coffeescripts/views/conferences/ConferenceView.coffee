#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'i18n!conferences'
  'jquery'
  'Backbone'
  'jst/conferences/newConference'
  'str/htmlEscape'
  'jquery.google-analytics'
  'compiled/jquery.rails_flash_notifications'
], (I18n, $, {View}, template, htmlEscape) ->

  class ConferenceView extends View

    tagName: 'li'

    className: 'conference'

    template: template

    events:
      'click .edit_conference_link': 'edit'
      'click .delete_conference_link': 'delete'
      'click .close_conference_link': 'close'
      'click .start-button': 'start'
      'click .external_url': 'external'
      'click .publish_recording_link': 'publish_recording'
      'click .unpublish_recording_link': 'unpublish_recording'
      'click .delete_recording_link': 'delete_recording'
      'click .protect_recording_link':   'protect_recording'
      'click .unprotect_recording_link':   'unprotect_recording'
      'mouseenter .btn.btn-small.publish' : 'mouse_enter'
      'mouseleave .btn.btn-small.publish' : 'mouse_leave'
      'mouseenter .btn.btn-small.protect' : 'mouse_enter'
      'mouseleave .btn.btn-small.protect' : 'mouse_leave'

    initialize: ->
      super
      @model.on('change', @render)

    edit: (e) ->
      # refocus if edit not finalized
      @$el.find('.al-trigger').focus()

    delete: (e) ->
      e.preventDefault()
      if !confirm I18n.t('confirm.delete', "Are you sure you want to delete this conference?")
        $(e.currentTarget).parents('.inline-block').find('.al-trigger').focus()
      else
        currentCog = $(e.currentTarget).parents('.inline-block').find('.al-trigger')[0]
        allCogs = $('#content .al-trigger').toArray()
        # Find the preceeding cog
        curIndex = allCogs.indexOf(currentCog)
        if (curIndex > 0)
          allCogs[curIndex - 1].focus()
        else
          $('.new-conference-btn').focus()
        @model.destroy success: =>
          $.screenReaderFlashMessage(I18n.t('Conference was deleted'))

    close: (e) ->
      e.preventDefault()
      return if !confirm(I18n.t('confirm.close', "Are you sure you want to end this conference?\n\nYou will not be able to reopen it."))
      $.ajaxJSON($(e.currentTarget).attr('href'), "POST", {}, (data) =>
        window.router.close(@model)
      )

    start: (e) ->
      if @model.isNew()
        e.preventDefault()
        return

      w = window.open(e.currentTarget.href, '_blank')
      if (!w) then return
      e.preventDefault()

      w.onload = () ->
        window.location.reload(true)

      # cross-domain
      i = setInterval(() ->
        if (!w) then return
        try
          href = w.location.href
        catch e
          clearInterval(i)
          window.location.reload(true)
      , 100)

    external: (e) ->
      # TODO: kill this if it's not in use anywhere
      $.trackEvent('Conference', 'External URL')
      e.preventDefault()
      loading_text = I18n.t('loading_urls_message', "Loading, please wait...")
      $self = $(e.currentTarget)
      link_text = $self.text()
      if (link_text == loading_text)
        return

      $self.text(loading_text)
      $.ajaxJSON($self.attr('href'), 'GET', {}, (data) ->
        $self.text(link_text)
        if (data.length == 0)
          $.flashError(I18n.t('no_urls_error', "Sorry, it looks like there aren't any %{type} pages for this conference yet.", {type: $self.attr('name')}))
        else if (data.length > 1)
          $box = $(document.createElement('DIV'))
          $box.append($("<p />").text(I18n.t('multiple_urls_message', "There are multiple %{type} pages available for this conference. Please select one:", {type: $self.attr('name')})))
          for datum in data
            $a = $("<a />", {href: datum.url || $self.attr('href') + '&url_id=' + datum.id, target: '_blank'})
            $a.text(datum.name)
            $box.append($a).append("<br>")

          $box.dialog(
            width: 425,
            minWidth: 425,
            minHeight: 215,
            resizable: true,
            height: "auto",
            title: $self.text()
          )
        else
          window.open(data[0].url)
      )

    publish_recording: (e) ->
      this.perform_action_on_recording(e, 'publish')

    unpublish_recording: (e) ->
      this.perform_action_on_recording(e, 'unpublish')

    protect_recording: (e) ->
      this.perform_action_on_recording(e, 'protect')

    unprotect_recording: (e) ->
      this.perform_action_on_recording(e, 'unprotect')

    delete_recording: (e) ->
      return if !confirm(I18n.t('recordings.confirm.delete', "Are you sure you want to delete this recording?\n\nYou will not be able to reopen it."))
      this.perform_action_on_recording(e, 'delete')

    perform_action_on_recording: (e, action_requested) ->
      e.preventDefault()
      parent = $(e.currentTarget).parent()
      params = {recording_id: parent.data("id")}
      desired_state = if action_requested == 'delete' || action_requested == 'publish' || action_requested == 'protect' then "true" else "false"
      if action_requested == 'delete'
        this.toggleDeleteButton(parent, "processing")
        this.toggleRecordingLink(parent, {published: "false"})
        action = 'delete'
      else
        this.displaySpinner($(e.currentTarget))
        action = if action_requested == 'publish' || action_requested == 'unpublish' then "publish" else "protect"
        params[action] = desired_state
      $.ajaxJSON(parent.data('url') + "/" + action + "_recording", "POST", params,
        (data) =>
          if action == 'delete'
            current_state = if $.isEmptyObject(data) then "true" else "false"
          else if action == 'publish'
            current_state = data.published
          else
            current_state = data.protected
          if current_state == desired_state
            if action == 'delete'
              this.removeRecordingRow(parent)
            else
              this.togglePublishOrProtectButton(parent, action, current_state)
              this.toggleRecordingLink(parent, data)
          else
            this.ensure_action_performed_on_recording({attempt: 1, action: action, parent: parent, desired_state: desired_state})
          return
      )
      return

    ensure_action_performed_on_recording: (payload) ->
      $.ajaxJSON(payload.parent.data('url') + "/get_recording", "POST", {
          recording_id: payload.parent.data("id"),
        }, (data) =>
          if payload.action == 'delete'
            current_state = if $.isEmptyObject(data) then "true" else "false"
          else if payload.action == 'publish'
            current_state = data.published
          else
            current_state = data.protected
          if current_state == payload.desired_state
            if payload.action == 'delete'
              this.removeRecordingRow(payload.parent)
            else
              this.togglePublishOrProtectButton(payload.parent, payload.action, current_state)
              this.toggleRecordingLink(payload.parent, data)
          else if payload.attempt < 5
            payload['attempt'] = payload['attempt'] + 1
            setTimeout((=> this.ensure_action_performed_on_recording(payload); return;), payload.attempt * 1000)
          else
            $.flashError(I18n.t('conferences.recordings.action_error', "Sorry, the action performed on this recording failed. Try again later"))
            if payload.action == 'delete'
              this.toggleDeleteButton(payload.parent, "processed")
            else
              this.togglePublishOrProtectButton(payload.parent, payload.action, current_state)
            this.toggleRecordingLink(payload.parent, data)
          return
      )
      return

    mouse_enter: (e) ->
      elem = $(e.currentTarget)
      if elem.data("publish")==true || elem.data("protect")==true
        elem.removeClass(if elem.data("publish") then 'icon-publish' else 'icon-lock')
        elem.addClass(if elem.data("publish") then 'icon-unpublish unpublish_recording_link' else 'icon-unlock unprotect_recording_link')
        elem.text(if elem.data("publish") then I18n.t('conferences.recordings.unpublish', 'Unpublish') else I18n.t('conferences.recordings.ubprotect', 'Unprotect'))
      else if elem.data("publish")==false || elem.data("protect")==false
        elem.removeClass(if elem.data("publish")==false then 'icon-unpublish' else 'icon-unlock')
        elem.addClass(if elem.data("publish")==false then 'icon-publish publish_recording_link' else 'icon-lock protect_recording_link')
        elem.text(if elem.data("publish")==false then I18n.t('conferences.recordings.publish', 'Publish') else I18n.t('conferences.recordings.protect', 'Protect'))

    mouse_leave: (e) ->
      elem = $(e.currentTarget)
      if elem.data("publish")==true || elem.data("protect")==true
        elem.removeClass(if elem.data("publish") then 'icon-unpublish unpublish_recording_link' else 'icon-unlock unprotect_recording_link')
        elem.addClass(if elem.data("publish") then 'icon-publish' else 'icon-lock')
        elem.text(if elem.data("publish") then I18n.t('conferences.recordings.published', 'Published') else I18n.t('conferences.recordings.protected', 'Protected'))
      else if elem.data("publish")==false || elem.data("protect")==false
        elem.removeClass(if elem.data("publish")==false then 'icon-publish publish_recording_link' else 'icon-lock protect_recording_link')
        elem.addClass(if elem.data("publish")==false then 'icon-unpublish' else 'icon-unlock')
        elem.text(if elem.data("publish")==false then I18n.t('conferences.recordings.unpublished', 'Unpublished') else I18n.t('conferences.recordings.ubprotected', 'Unprotected'))

    ## BBB FRONT END FUNCTIONS FOR PUBLISH, PROTECT AND DELETE RECORDINGS
    displaySpinner: (elem, publish, protect) ->
      elem.prev('img.loader').show()
      elem.remove()

    togglePublishOrProtectButton: (parent, action, data) ->
      actionHtml = action
      dataHtml = data
      classHtml = 'btn btn-small ' + action
      if action == 'publish'
        if data == 'true'
          classHtml += ' icon-publish'
          text = I18n.t('conferences.recordings.published', 'Published')
        else
          classHtml += ' icon-unpublish'
          text = I18n.t('conferences.recordings.unpublished', 'Unpublished')
      else if action == 'protect'
        if data == 'true'
          classHtml += ' icon-lock'
          text = I18n.t('conferences.recordings.protected', 'Protected')
        else
          classHtml += ' icon-unlock'
          text = I18n.t('conferences.recordings.unprotected', 'Unprotected')
      spinner = parent.find('img.loader[data-action="' + action + '"]')
      spinner.hide()
      $('<a class="' + classHtml + '" data-' + actionHtml + '="' + dataHtml + '">' + htmlEscape(text) + '</a>').insertAfter(spinner)

    toggleRecordingLink: (parent, data) ->
      thumbnails = $('.recording-thumbnails[data-id="' + parent.data("id") + '"]')
      link = $('a[data-id="' + parent.data("id") + '"]')
      ext_icon = []
      if data.published == "true"
        i = 0
        while i < link.length
          icon = $(link[i]).find(".ui-icon.ui-icon-extlink.ui-icon-inline")
          if icon.length
            icon.show()
          else
            $(link[i]).addClass('external')
            $(link[i]).append('<span class="ui-icon ui-icon-extlink ui-icon-inline" title="' + htmlEscape(I18n.t('external_link', "Links to an external site.")) + '"></span>')
          for format in data.recording_formats
            if $(link[i]).data('format') == format.type
              $(link[i]).attr("href", format.url)
          i++
        link.attr("target", "_blank")
        $(thumbnails).children('img').each ->
          $(@).attr('src', $(@).attr('data-src'))
        thumbnails.removeClass('hidden')
      else
        link.removeAttr("href")
        link.removeAttr("target")
        i = 0
        while i < link.length
          $(link[i]).find(".ui-icon.ui-icon-extlink.ui-icon-inline").hide()
          i++
        $(thumbnails).children('img').each ->
          $(@).attr('src', '')
        thumbnails.addClass('hidden')

    toggleDeleteButton: (parent, data) ->
      buttons = $('.ig-button[data-id="' + parent.data("id") + '"]')
      spinner = $('.ig-loader[data-id="' + parent.data("id") + '"]')
      if data == 'processing'
        buttons.hide()
        spinner.show()
      else
        spinner.hide()
        buttons.show()
      return

    removeRecordingRow: (parent) ->
      row = $('.ig-row[data-id="' + parent.data("id") + '"]')
      list = $(row.parent().parent())
      if list.children().length == 1
        container = $(list.parent())
        container.remove()
      else
        list_element = $(row.parent())
        list_element.remove()
