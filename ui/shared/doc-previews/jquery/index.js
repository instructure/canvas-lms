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

import INST from 'browser-sniffer'
import I18n from 'i18n!jquery_doc_previews'
import $ from 'jquery'
import _ from 'underscore'
import htmlEscape from 'html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import {trackEvent} from '@canvas/google-analytics'
import '@canvas/jquery/jquery.instructure_misc_helpers' /*  /\$\.uniq/, capitalize */
import '@canvas/loading-image'
import sanitizeUrl from 'sanitize-url'

// first element in array is if scribd can handle it, second is if google can.
const previewableMimeTypes = {
  'application/vnd.openxmlformats-officedocument.wordprocessingml.template': [1, 1],
  'application/vnd.oasis.opendocument.spreadsheet': [1, 1],
  'application/vnd.sun.xml.writer': [1, 1],
  'application/excel': [1, 1],
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': [1, 1],
  'text/rtf': [1, 1],
  'application/vnd.openxmlformats-officedocument.spreadsheetml.template': [1, 1],
  'application/vnd.sun.xml.impress': [1, 1],
  'application/vnd.sun.xml.calc': [1, 1],
  'application/vnd.ms-excel': [1, 1],
  'application/msword': [1, 1],
  'application/mspowerpoint': [1, 1],
  'application/rtf': [1, 1],
  'application/vnd.oasis.opendocument.presentation': [1, 1],
  'application/vnd.oasis.opendocument.text': [1, 1],
  'application/vnd.openxmlformats-officedocument.presentationml.template': [1, 1],
  'application/vnd.openxmlformats-officedocument.presentationml.slideshow': [1, 1],
  'text/plain': [1, 1],
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': [1, 1],
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': [1, 1],
  'application/postscript': [1, 1],
  'application/pdf': [1, 1],
  'application/vnd.ms-powerpoint': [1, 1]
}

// check to see if a file of a certan mimeType is previewable inline in the browser by either scribd or googleDocs
// ex: $.isPreviewable("application/mspowerpoint")  -> true
//     $.isPreviewable("application/rtf", 'google') -> false
$.isPreviewable = function(mimeType, service) {
  return (
    previewableMimeTypes[mimeType] &&
    (!service ||
      (!INST['disable' + $.capitalize(service) + 'Previews'] &&
        previewableMimeTypes[mimeType][{scribd: 0, google: 1}[service]]))
  )
}

$.fn.loadDocPreview = function(options) {
  return this.each(function() {
    const $this = $(this),
      opts = $.extend(
        {
          width: '100%',
          height: '400px'
        },
        $this.data(),
        options
      )

    function tellAppIViewedThisInline(serviceUsed) {
      // if I have a url to ping back to the app that I viewed this file inline, ping it.
      if (opts.attachment_view_inline_ping_url) {
        $.ajaxJSON(
          opts.attachment_view_inline_ping_url,
          'POST',
          {},
          () => {},
          () => {}
        )
        trackEvent(
          'Doc Previews',
          serviceUsed,
          JSON.stringify(opts, [
            'attachment_id',
            'submission_id',
            'mimetype',
            'crocodoc_session_url',
            'canvadoc_session_url'
          ])
        )
      }
    }

    if (opts.crocodoc_session_url) {
      const sanitizedUrl = sanitizeUrl(opts.crocodoc_session_url)
      var iframe = $('<iframe/>', {
        src: sanitizedUrl,
        width: opts.width,
        height: opts.height,
        allowfullscreen: '1',
        id: opts.id
      })
      iframe.appendTo($this)
      iframe.load(() => {
        tellAppIViewedThisInline('crocodoc')
        if ($.isFunction(opts.ready)) opts.ready()
      })
    } else if (opts.canvadoc_session_url) {
      const canvadocWrapper = $(
        '<div style="overflow: auto; resize: vertical;\
        border: 1px solid transparent; height: 100%;"/>'
      )
      canvadocWrapper.appendTo($this)

      const minHeight = opts.iframe_min_height !== undefined ? opts.iframe_min_height : '800px'
      const sanitizedUrl = sanitizeUrl(opts.canvadoc_session_url)
      var iframe = $('<iframe/>', {
        src: sanitizedUrl,
        width: opts.width,
        allowfullscreen: '1',
        css: {border: 0, overflow: 'auto', height: '99%', 'min-height': minHeight},
        id: opts.id
      })
      iframe.appendTo(canvadocWrapper)
      iframe.load(() => {
        tellAppIViewedThisInline('canvadocs')
        if ($.isFunction(opts.ready)) opts.ready()
      })
    } else if (
      (!INST.disableGooglePreviews &&
        (!opts.mimetype || $.isPreviewable(opts.mimetype, 'google')) &&
        opts.attachment_id) ||
      opts.public_url
    ) {
      // else if it's something google docs preview can handle and we can get a public url to this document.
      const loadGooglePreview = function() {
        // this handles both ssl and plain http.
        const googleDocPreviewUrl =
          '//docs.google.com/viewer?' +
          $.param({
            embedded: true,
            url: opts.public_url
          })
        if (!opts.ajax_valid || opts.ajax_valid()) {
          $(
            '<iframe src="' +
              htmlEscape(googleDocPreviewUrl) +
              '" height="' +
              opts.height +
              '" width="100%" />'
          )
            .appendTo($this)
            .load(() => {
              tellAppIViewedThisInline('google')
              if ($.isFunction(opts.ready)) {
                opts.ready()
              }
            })
        }
      }
      if (opts.public_url) {
        loadGooglePreview()
      } else if (opts.attachment_id) {
        let url = `/api/v1/files/${opts.attachment_id}/public_url.json`
        if (opts.submission_id) {
          url += '?' + $.param({submission_id: opts.submission_id})
        }
        if (opts.verifier) {
          url += `${opts.submission_id ? '&' : '?'}verifier=${opts.verifier}`
        } else {
          const match = window.location.search.match(/verifier=([^&]+)(?:&|$)/)
          const ver = match && match[1]
          if (ver) {
            url += `${opts.submission_id ? '&' : '?'}verifier=${ver}`
          }
        }
        $this.loadingImage()
        $.ajaxJSON(url, 'GET', {}, data => {
          $this.loadingImage('remove')
          if (data && data.public_url) {
            $.extend(opts, data)
            loadGooglePreview()
          }
        })
      }
    } else {
      // else fall back with a message that the document can't be viewed inline
      if (opts.attachment_preview_processing) {
        $this.html(
          '<p>' +
            htmlEscape(
              I18n.t(
                'errors.document_preview_processing',
                'The document preview is currently being processed. Please try again later.'
              )
            ) +
            '</p>'
        )
      } else {
        $this.html(
          '<p>' +
            htmlEscape(
              I18n.t(
                'errors.cannot_view_document_in_canvas',
                'This document cannot be displayed within Canvas.'
              )
            ) +
            '</p>'
        )
      }
    }
  })
}
