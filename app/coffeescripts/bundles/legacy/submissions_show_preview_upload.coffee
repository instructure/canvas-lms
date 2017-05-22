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
  "jquery",
  "i18n!submissions.show_preview",
  "swfobject",
  "jqueryui/dialog",
  "jquery.doc_previews"
], ($, I18n, swfobject, _docPreviews) ->
  $(document).ready ->
    $("a.flash").click ->
      swfobject.embedSWF $(this).attr("href"), "main", "100%", "100%", "9.0.0", false, null,
        wmode: "opaque"
      , null
      false

    if $.filePreviewsEnabled()
      $(".modal_preview_link").live "click", ->
        #overflow:hidden is because of some weird thing where the google doc preview gets double scrollbars
        $("<div style=\"padding:0; overflow:hidden;\">").dialog(
          title: I18n.t("preview_title", "Preview of %{title}", { title: $(this).data("dialog-title") })
          width: $(document).width() * .95
          height: $(document).height() * .75
        ).loadDocPreview $.extend(
          height: "100%"
        , $(this).data())
        false