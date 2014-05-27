/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
define([
  'INST' /* INST */,
  'i18n!instructure',
  'jquery' /* jQuery, $ */,
  'underscore',
  'vendor/scribd.view' /* scribd */,
  'str/htmlEscape' /* htmlEscape, /\$\.h/ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.google-analytics' /* trackEvent */,
  'jquery.instructure_misc_helpers' /*  /\$\.uniq/, capitalize */,
  'jquery.loadingImg' /* loadingImage */
], function(INST, I18n, $, _, scribd, htmlEscape) {

  // first element in array is if scribd can handle it, second is if google can.
  var previewableMimeTypes = {
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template":   [1, 1],
      "application/vnd.oasis.opendocument.spreadsheet":                            [1, 1],
      "application/vnd.sun.xml.writer":                                            [1, 1],
      "application/excel":                                                         [1, 1],
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":         [1, 1],
      "text/rtf":                                                                  [1, 1],
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template":      [1, 1],
      "application/vnd.sun.xml.impress":                                           [1, 1],
      "application/vnd.sun.xml.calc":                                              [1, 1],
      "application/vnd.ms-excel":                                                  [1, 1],
      "application/msword":                                                        [1, 1],
      "application/mspowerpoint":                                                  [1, 1],
      "application/rtf":                                                           [1, 1],
      "application/vnd.oasis.opendocument.presentation":                           [1, 1],
      "application/vnd.oasis.opendocument.text":                                   [1, 1],
      "application/vnd.openxmlformats-officedocument.presentationml.template":     [1, 1],
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow":    [1, 1],
      "text/plain":                                                                [1, false],
      "application/vnd.openxmlformats-officedocument.presentationml.presentation": [1, 1],
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document":   [1, 1],
      "application/postscript":                                                    [1, 1],
      "application/pdf":                                                           [1, 1],
      "application/vnd.ms-powerpoint":                                             [1, 1]

  };

  $.filePreviewsEnabled = function(){
    return !(
      INST.disableCrocodocPreviews &&
      INST.disableScribdPreviews &&
      INST.disableGooglePreviews
    );
  }

  // check to see if a file of a certan mimeType is previewable inline in the browser by either scribd or googleDocs
  // ex: $.isPreviewable("application/mspowerpoint")  -> true
  //     $.isPreviewable("application/rtf", 'google') -> false
  $.isPreviewable = function(mimeType, service){
    return $.filePreviewsEnabled() && previewableMimeTypes[mimeType] && (
      !service ||
      (!INST['disable' + $.capitalize(service) + 'Previews'] && previewableMimeTypes[mimeType][{scribd: 0, google: 1}[service]])
    );
  };

  $.fn.loadDocPreview = function(options) {
    // if it is a scribd doc and flash is available
    var flashVersion = swfobject.getFlashPlayerVersion(),
        hasGoodEnoughFlash = flashVersion && flashVersion.major > 9,
        scribdHtml5 = INST.enableScribdHtml5;

    return this.each(function(){
      var $this = $(this),
          opts = $.extend({
            width: '100%',
            height: '400px'
          }, $this.data(), options);

      function tellAppIViewedThisInline(serviceUsed){
        // if I have a url to ping back to the app that I viewed this file inline, ping it.
        if (opts.attachment_view_inline_ping_url) {
          $.ajaxJSON(opts.attachment_view_inline_ping_url, 'POST', {}, function() { }, function() { });
          $.trackEvent('Doc Previews', serviceUsed, JSON.stringify(opts, ['attachment_id', 'submission_id', 'mimetype', 'crocodoc_session_url', 'canvadoc_session_url', 'scribd_doc_id']));
        }
      }

      if (!INST.disableCrocodocPreviews && opts.crocodoc_session_url) {
        var iframe = $('<iframe/>', {
            src: opts.crocodoc_session_url,
            width: opts.width,
            height: opts.height
        });
        iframe.appendTo($this);
        iframe.load(function() {
          tellAppIViewedThisInline('crocodoc');
          if ($.isFunction(opts.ready))
            opts.ready();
        });
      }
      else if (opts.canvadoc_session_url) {
        var iframe = $('<iframe/>', {
            src: opts.canvadoc_session_url,
            width: opts.width,
            height: opts.height,
            css: {border: 0}
        });
        iframe.appendTo($this);
        iframe.load(function() {
          tellAppIViewedThisInline('canvadocs');
          if ($.isFunction(opts.ready))
            opts.ready();
        });
      }
      else if (!INST.disableScribdPreviews && opts.scribd_doc_id && opts.scribd_access_key &&
          (scribdHtml5 || scribd && hasGoodEnoughFlash)) {
        if (scribdHtml5) {
          var scribdParams = $.extend({
              'auto_size': false,
              'height': opts.height,
              'jsapi_version': 2
            }, opts.scribdParams);

          var scribdIframeUrl = '//www.scribd.com/embeds/' + opts.scribd_doc_id + '/content?' + $.param({
              start_page: 1,
              view_mode: 'list',
              access_key: opts.scribd_access_key
            });

          $('<iframe class="scribd_iframe_embed" src="' + scribdIframeUrl + '" height="' + scribdParams.height  +
              '" data-auto-height="' + scribdParams.auto_size + '" width="100%" />')
            .appendTo($this)
            .load(function() {
                tellAppIViewedThisInline('scribd');
                if ($.isFunction(opts.ready)) opts.ready();
              });

        } else if (scribd && hasGoodEnoughFlash){
          var scribdDoc = scribd.Document.getDoc( opts.scribd_doc_id, opts.scribd_access_key ),
              id = $this.attr('id'),
              // see http://www.scribd.com/developers/api?method_name=Javascript+API for an explaination of these options
              scribdParams = $.extend({
                'jsapi_version': 1,
                'disable_related_docs': true, //Disables the related documents tab in List Mode.
                'auto_size' : false, //When false, this parameter forces Scribd Reader to use the provided width and height rather than using a width multiplier of 85/110.
                'height' : opts.height,
                'use_ssl' : 'https:' == document.location.protocol
              }, opts.scribdParams);

          if (!id) {
            id = _.uniqueId("scribd_preview_");
            $this.attr('id', id);
          }
          $.each(scribdParams, function(key, value){
            scribdDoc.addParam(key, value);
          });
          if ($.isFunction(opts.ready)) {
            scribdDoc.addEventListener('iPaperReady', opts.ready);
          }
          scribdDoc.write( id );

          // this is a hack so that the <embed> doesn't throw a bunch of these errors after it is .remove()d:
          // Uncaught TypeError: Object #<HTMLEmbedElement> has no method 'keyboardShortcut(Up/Down)'
          // They come from the actionscript running in their viewer:
          // see: http://dragstudio.com/app/ScribdViewer/javascript/_-0j.as
          // and http://groups.google.com/group/scribd-platform-developers/msg/46a4f12db73d02d8
          this.childNodes[0].keyboardShortcutDown = this.childNodes[0].keyboardShortcutUp = function(){};

          tellAppIViewedThisInline('scribd');
        }
      } else if (!INST.disableGooglePreviews && (!opts.mimeType || $.isPreviewable(opts.mimeType, 'google')) && opts.attachment_id || opts.public_url){
        // else if it's something google docs preview can handle and we can get a public url to this document.
        function loadGooglePreview(){
          // this handles both ssl and plain http.
          var googleDocPreviewUrl = '//docs.google.com/viewer?' + $.param({
            embedded: true,
            url: opts.public_url
          });
          if (!opts.ajax_valid || opts.ajax_valid()){
            $('<iframe src="' + googleDocPreviewUrl + '" height="' + opts.height  + '" width="100%" />')
              .appendTo($this)
              .load(function(){
                tellAppIViewedThisInline('google');
                if ($.isFunction(opts.ready)) {
                  opts.ready();
                }
              });
          }
        }
        if (opts.public_url) {
          loadGooglePreview()
        } else if (opts.attachment_id) {
          var url = '/api/v1/files/'+opts.attachment_id+'/public_url.json';
          if (opts.submission_id) {
            url += '?' + $.param({ submission_id: opts.submission_id });
          }
          $this.loadingImage();
          $.ajaxJSON(url, 'GET', {}, function(data){
            $this.loadingImage('remove');
            if (data && data.public_url) {
              $.extend(opts, data);
              loadGooglePreview();
            }
          });
        }
      } else if ($.filePreviewsEnabled()) {
        // else fall back with a message that the document can't be viewed inline
        if (opts.attachment_preview_processing) {
          $this.html('<p>' + htmlEscape(I18n.t('errors.document_preview_processing', 'The document preview is currently being processed. Please try again later.')) + '</p>');
        } else if (opts.attachment_scribd_render_url) {
          $this.html('<p>' + htmlEscape(I18n.t('errors.document_preview_processing', 'The document preview is currently being processed. Please try again later.')) + '</p>');
          $.ajaxJSON(opts.attachment_scribd_render_url, 'POST', {}, function() {}, function() {});
        } else {
          $this.html('<p>' + htmlEscape(I18n.t('errors.cannot_view_document_in_canvas', 'This document cannot be displayed within Canvas.')) + '</p>');
        }
      }
    });
  };

});
