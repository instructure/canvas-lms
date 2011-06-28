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
I18n.scoped("license_help", function(I18n) {
$(document).ready(function() {
  $(".license_help_link").live('click', function(event) {
    event.preventDefault();
    var $dialog = $("#license_help_dialog");
    var $select = $(this).prev("select");
    if($dialog.length == 0) {
      $dialog = $("<div/>").attr('id', 'license_help_dialog').hide();
      $dialog.html("Loading...");
      $("body").append($dialog);
      $.get("/partials/_license_help.html", function(html) {
        $dialog.html(html);
        $dialog.delegate('.option', 'click', function(event) {
          $(this).toggleClass('selected');
          if($(this).hasClass('selected')) {
            $dialog.find(".option.by").addClass('selected');
            if($(this).hasClass('sa')) {
              $dialog.find(".option.nd").removeClass('selected');
            } else if($(this).hasClass('nd')) {
              $dialog.find(".option.sa").removeClass('selected');
            }
          } else {
            if($(this).hasClass('by')) {
              $dialog.find(".option").removeClass('selected');
            }
          }
          $dialog.triggerHandler('option_change');
        });
        $dialog.bind('license_change', function(event, license) {
          $dialog.find(".license").removeClass('active').filter("." + license).addClass('active');
          $dialog.find(".option").removeClass('selected');
          if($dialog.find(".license.active").length == 0) {
            license = 'private';
            $dialog.find(".license.private").addClass('active');
          }
          $dialog.data('current_license', license);
          if(license.match(/^cc/)) {
            $dialog.find(".option.by").addClass('selected');
            if(license.match(/_sa/)) {
              $dialog.find(".option.sa").addClass('selected');
            }
            if(license.match(/_nc/)) {
              $dialog.find(".option.nc").addClass('selected');
            }
            if(license.match(/_nd/)) {
              $dialog.find(".option.nd").addClass('selected');
            }
          }
        });
        $dialog.bind('option_change', function() {
          var args = ['cc'], 
              licence;
          if($dialog.find(".option.by").hasClass('selected')) {
            args.push('by');
          }
          if($dialog.find(".option.nc").hasClass('selected')) {
            args.push('nc');
          }
          if($dialog.find(".option.nd").hasClass('selected')) {
            args.push('nd');
          }
          if($dialog.find(".option.sa").hasClass('selected')) {
            args.push('sa');
          }
          if(args.length == 1) {
            license = 'private';
          } else {
            license = args.join("_");
          }
          $dialog.triggerHandler('license_change', license);
        });
        $dialog.delegate('.select_license', 'click', function() {
          var $dialog_select = $dialog.data('select');
          if($dialog_select) {
            $dialog_select.val($dialog.data('current_license') || 'private');
          }
          $dialog.dialog('close');
        });
        $dialog.triggerHandler('license_change', $select.val() || "private");
      });
      $dialog.dialog({
        autoOpen: false,
        title: I18n.t("content_license_help", "Content Licensing Help"),
        width: 700,
        height: 360
      });
    }
    $dialog.find(".select_license").showIf($select.length > 0);
    $dialog.data('select', $select);
    $dialog.triggerHandler('license_change', $select.val() || "private");
    $dialog.dialog('open');
  });
});
});