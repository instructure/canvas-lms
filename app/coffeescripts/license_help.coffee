#
# Copyright (C) 2011 Instructure, Inc.
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
  'i18n!license_help'
  'jquery'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'jquery.loadingImg'
], (I18n, $) ->

  licenceTypes = ["by", "nc", "nd", "sa"]
  toggleButton = (el, check) -> $(el).toggleClass('selected', !!check).attr('aria-checked', !!check)
  checkButton = (el) -> toggleButton(el, true)
  uncheckButton = (el) -> toggleButton(el, false)
  $(".license_help_link").live "click", (event) ->
    event.preventDefault()
    $dialog = $("#license_help_dialog")
    $select = $(this).prev("select")
    if $dialog.length == 0
      $dialog = $("<div/>").attr("id", "license_help_dialog").hide().loadingImage().appendTo("body")
      .delegate(".option", "click", (event)->
        event.preventDefault()
        select = !$(this).is('.selected')
        toggleButton this, select
        if select
          checkButton $dialog.find(".option.by")
          if $(this).hasClass("sa")
            uncheckButton $dialog.find(".option.nd")
          else if $(this).hasClass("nd")
            uncheckButton $dialog.find(".option.sa")
        else if $(this).hasClass("by")
          uncheckButton $dialog.find(".option")
        $dialog.triggerHandler("option_change")
        return
      ).delegate(".select_license", "click", ()->
        $dialog.data("select").val($dialog.data("current_license") or "private") if $dialog.data("select")
        $dialog.dialog("close")
      ).bind("license_change", (event, license) ->
        $dialog.find(".license").removeClass("active").filter("." + license).addClass("active")
        uncheckButton $dialog.find(".option")
        if $dialog.find(".license.active").length == 0
          license = "private"
          $dialog.find(".license.private").addClass("active")
        $dialog.data "current_license", license
        if license.match(/^cc/)
          checkButton $dialog.find(".option.#{type}") for type in licenceTypes when type is 'by' or license.match("_#{type}")
      ).bind("option_change", ->
        args = [ "cc" ]
        args.push(type) for type in licenceTypes when $dialog.find(".option.#{type}").is(".selected")
        license = (if args.length == 1 then "private" else args.join("_"))
        $dialog.triggerHandler "license_change", license
      ).dialog(
        autoOpen: false
        title: I18n.t("content_license_help", "Content Licensing Help")
        width: 700
      )
      $.get "/partials/_license_help.html", (html) ->
        $dialog
          .loadingImage('remove')
          .html(html)
          .triggerHandler "license_change", $select.val() or "private"
    $dialog.find(".select_license").showIf $select.length
    $dialog.data "select", $select
    $dialog.triggerHandler "license_change", $select.val() or "private"
    $dialog.dialog "open"
