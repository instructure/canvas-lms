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
  'i18n!prerequisites_lookup',
  'jquery',
  'str/htmlEscape',
  'context_modules',
  'jquery.ajaxJSON',
  'jquery.instructure_misc_helpers'
], function(I18n, $, htmlEscape) {

  $(document).ready(function() {
    var $link = $("#module_prerequisites_lookup_link");
    var url = $link.attr('href');
    $.ajaxJSON(url, 'GET', {}, function(data) {
      if(data.locked === false) {
        window.reload();
        return;
      }
      var $ul = $("<ul/>");
      $ul.attr('id', 'module_prerequisites_list');
      for(var idx in data.modules) {
        var module = data.modules[idx];
        var $li = $("<li/>");
        $li.addClass('module');
        $li.click(function() {
          $(this).find("ul").toggle();
        });
        $li.toggleClass('locked', !!module.locked);
        var $h3 = $("<h3/>");
        $h3.text(module.name);
        $li.append($h3);
        if(module.prerequisites && module.prerequisites.length > 0) {
          var $pres = $("<ul/>");
          for(var jdx in module.prerequisites) {
            var pre = module.prerequisites[jdx];
            var $pre = $("<li/>");
            $pre.addClass('requirement');
            $pre.toggleClass('locked_requirement', !pre.available);
            var $a = $("<a/>");
            $a.attr('href', pre.url);
            $a.text(pre.title);
            $pre.append($a);
            var desc = pre.requirement_description;
            if(desc) {
              var $div = $("<div/>");
              $div.addClass('description');
              $div.text(desc);
              $pre.append($div);
            }
            $pres.append($pre);
          }
          $li.append($pres);
        }
        $ul.append($li);
      }
      $link.after($ul);
      var header = I18n.t("headers.completion_prerequisites", "Completion Prerequisites");
      var sentence = I18n.beforeLabel(I18n.t("labels.requirements_must_be_completed", "The following requirements need to be completed before this page will be unlocked"));
      $link.after("<br/><h3 style='margin-top: 15px;'>" + htmlEscape(header) + "</h3>" + htmlEscape(sentence));
      $link.prev("a").hide();
    }, function(data) {});
  });

});
