/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import I18n from 'i18n!collaborations'
import $ from 'jquery'
import './jquery.ajaxJSON'
import './jquery.instructure_forms' /* fillFormData, getFormData, errorBox */
import 'jqueryui/dialog'
import './jquery.instructure_misc_plugins' /* .dim, confirmDelete, fragmentChange, showIf */
import './jquery.templateData' /* getTemplateData */
import './vendor/jquery.scrollTo'
import 'compiled/jquery.rails_flash_notifications'

const CollaborationsPage = {}

CollaborationsPage.Util = {
  removeCollaboration($collaboration) {
    const visibleCollaborations = $('#collaborations .collaboration:visible')

    if (visibleCollaborations.length <= 1) {
      $('#no_collaborations_message').slideDown()
      $('.add_collaboration_link').click()
      $collaboration.remove()
    } else {
      const sortedCollaborations = visibleCollaborations
        .toArray()
        .sort((a, b) => $(a).data('id') - $(b).data('id'))
      if (sortedCollaborations.length <= sortedCollaborations.indexOf($collaboration[0]) + 1) {
        $(sortedCollaborations[sortedCollaborations.indexOf($collaboration[0]) - 1])
          .find('.title')
          .focus()
      } else {
        $(sortedCollaborations[sortedCollaborations.indexOf($collaboration[0]) + 1])
          .find('.title')
          .focus()
      }
      $collaboration.slideUp(() => {
        $collaboration.remove()
      })
    }
  },

  collaborationUrl(id) {
    return window.location.toString() + '/' + id
  },

  openCollaboration(id) {
    window.open(CollaborationsPage.Util.collaborationUrl(id))
  }
}

CollaborationsPage.Events = {
  init() {
    $('#delete_collaboration_dialog .cancel_button').on('click', this.onClose)
    $('#delete_collaboration_dialog .delete_button').on('click', this.onDelete)
    $(document).fragmentChange(this.onFragmentChange)
    $('#collaboration_collaboration_type')
      .on('change', this.onTypeChange)
      .change()
    $(window).on('externalContentReady', this.onExternalContentReady.bind(this))
    $('.before_external_content_info_alert, .after_external_content_info_alert')
      .on('focus', function(e) {
        $(this).removeClass('screenreader-only')
        $('#lti_new_collaboration_iframe').addClass('info_alert_outline')
      })
      .on('blur', function(e) {
        $(this).addClass('screenreader-only')
        $('#lti_new_collaboration_iframe').removeClass('info_alert_outline')
      })
  },

  onClose(e) {
    $('#delete_collaboration_dialog').dialog('close')
  },

  onDelete(e) {
    const deleteDocument = $(this).hasClass('delete_document_button'),
      data = {delete_doc: deleteDocument},
      $collaboration = $('#delete_collaboration_dialog').data('collaboration'),
      url = $collaboration.find('.delete_collaboration_link').attr('href')

    $collaboration.dim()
    $('#delete_collaboration_dialog').dialog('close')

    $.ajaxJSON(
      url,
      'DELETE',
      data,
      data => {
        CollaborationsPage.Util.removeCollaboration($collaboration)
        $.screenReaderFlashMessage(I18n.t('Collaboration was deleted'))
      },
      $.noop
    )
  },

  onFragmentChange(e, hash) {
    if (hash !== '#add_collaboration') return

    if ($('#collaborations .collaboration').length == 0) {
      $('.add_collaboration_link').click()
    }
  },

  onTypeChange(e) {
    let name = $(this).val(),
      type = name,
      launch_url = $(this)
        .find('option:selected')
        .data('launch-url'),
      $description

    if (launch_url) {
      $('.collaborate_data, #google_docs_description').hide()
      $('#collaborate_authorize_google_docs').hide()
      $('#lti_new_collaboration_iframe')
        .attr('src', launch_url)
        .show()
      $('.before_external_content_info_alert, .after_external_content_info_alert').show()
    } else {
      $('#lti_new_collaboration_iframe').hide()
      $('.before_external_content_info_alert, .after_external_content_info_alert').hide()
      $('.collaborate_data, #google_docs_description').show()
      if (ENV.collaboration_types) {
        for (const i in ENV.collaboration_types) {
          const collaboration = ENV.collaboration_types[i]

          if (collaboration.name === name) {
            type = collaboration.type
          }
        }
      }

      $('.collaboration_type').hide()

      $description = $('#new_collaboration #' + type + '_description')
      $description.show()

      $('.collaborate_data').showIf(!$description.hasClass('unauthorized'))
      $('.collaboration_authorization').hide()
      $('#collaborate_authorize_' + type).showIf($description.hasClass('unauthorized'))
    }
  },

  onExternalContentReady(e, data) {
    const contentItem = {contentItems: JSON.stringify(data.contentItems)}
    if (data.service_id) {
      this.updateCollaboration(contentItem, data.service_id)
    } else {
      this.createCollaboration(contentItem)
    }
  },

  updateCollaboration(contentItem, collab_id) {
    const url = $('.collaboration_' + collab_id + ' a.title')[0].href
    $.ajaxJSON(url, 'PUT', contentItem, this.collaborationSuccess, msg => {
      $.screenReaderFlashMessage(I18n.t('Collaboration update failed'))
    })
  },

  createCollaboration(contentItem) {
    const url = $('#new_collaboration').attr('action')
    $.ajaxJSON(url, 'POST', contentItem, this.collaborationSuccess, msg => {
      $.screenReaderFlashMessage(I18n.t('Collaboration creation failed'))
    })
  },

  collaborationSuccess(msg) {
    CollaborationsPage.Util.openCollaboration(msg.collaboration.id)
    window.location.reload()
  }
}

$(document).ready(CollaborationsPage.Events.init.bind(CollaborationsPage.Events))

export default CollaborationsPage
