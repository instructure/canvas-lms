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
  '../../jquery.rails_flash_notifications'
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
      'click .delete_recording_link': 'deleteRecording'

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

    deleteRecording: (e) ->
      e.preventDefault()
      if confirm I18n.t("Are you sure you want to delete this recording?")
        $button = $(e.currentTarget).parents('div.ig-button')
        $.ajaxJSON($button.data('url') + "/recording", "DELETE", {
            recording_id: $button.data("id"),
          }
        ).done( (data, status) =>
          if data.deleted
            return @removeRecordingRow($button)
          $.flashError(I18n.t("Sorry, the action performed on this recording failed. Try again later"))
        ).fail( (xhr, status) =>
          $.flashError(I18n.t("Sorry, the action performed on this recording failed. Try again later"))
        )

    removeRecordingRow: ($button) =>
      $row = $('.ig-row[data-id="' + $button.data("id") + '"]')
      $conferenceId = $($row.parents('div.ig-sublist')).data('id')
      $row.parents('li.recording').remove()
      @updateConferenceDetails($conferenceId)
      $.screenReaderFlashMessage(I18n.t('Recording was deleted'))

    updateConferenceDetails: (id) =>
      $info = $('div.ig-row#conf_' + id).find('div.ig-info')
      $detailRecordings = $info.find('div.ig-details__item-recordings')
      $recordings = $('.ig-sublist#conference-' + id)
      recordings = $recordings.find('li.recording').length
      if recordings > 1
        $detailRecordings.text(I18n.t("%{count} Recordings", {count: recordings}))
        return
      if recordings == 1
        $detailRecordings.text(I18n.t("%{count} Recording", {count: 1}))
        return
      $detailRecordings.remove()
      $recordings.remove()
      # Shift the link to text
      $link = $info.children('a.ig-title')
      $text = $('<span />').addClass('ig-title').html($link.text())
      $info.prepend($text)
      $link.remove()
