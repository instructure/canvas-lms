//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import swfobject from 'swfobject'
import 'jqueryui/dialog'
import {loadDocPreview} from '@instructure/canvas-rce/es/enhance-user-content/doc_previews'

const I18n = useI18nScope('submissions.show_preview')

$(document).ready(() => {
  $('a.flash').click(function () {
    swfobject.embedSWF(
      $(this).attr('href'),
      'main',
      '100%',
      '100%',
      '9.0.0',
      false,
      null,
      {wmode: 'opaque'},
      null
    )
    return false
  })

  $(document).on('click', '.modal_preview_link', function () {
    // overflow:hidden is because of some weird thing where the google doc preview gets double scrollbars
    const dialog = $('<div style="padding:0; overflow:hidden;">').dialog({
      title: I18n.t('preview_title', 'Preview of %{title}', {
        title: $(this).data('dialog-title'),
      }),
      width: $(document).width() * 0.95,
      height: $(document).height() * 0.75,
      modal: true,
      zIndex: 1000,
    })
    loadDocPreview(dialog[0], $.extend({height: '100%'}, $(this).data()))
    $('.submission_annotation.unread_indicator').hide()
    $('.file-upload-submission-attachment .modal_preview_link').attr(
      'title',
      I18n.t('Preview your submission and view teacher feedback, if available')
    )
    return false
  })
})
