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
  "i18n!context.undelete_index",
  "jquery.ajaxJSON",
  "jquery.instructure_misc_plugins"
], ($, I18n) ->
  $(document).ready ->
    $(".restore_link").click (event) ->
      event.preventDefault()
      $link = $(this)
      $item = $link.parents(".item")
      item_name = $.trim($item.find(".name").text())
      result = confirm(I18n.t("are_you_sure","Are you sure you want to restore %{item_name}?", item_name: item_name))
      if result
        $link.text I18n.t("restoring", "restoring...")
        $item.dim()
        $.ajaxJSON $link.attr("href"), "POST", {}, (->
          $item.slideUp ->
            $item.remove()
        ), ->
          $link.text I18n.t("restore_failed", "restore failed")