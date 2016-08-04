/**
 * Copyright (C) 2015 Instructure, Inc.
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
  'jquery', /* $ */
  'str/htmlEscape',
  'vendor/ui.selectmenu' /* /\.selectmenu/ */
], function($, htmlEscape) {

  var speedgraderSelectMenu = function(optionsHtml, delimiter){
    this.html = "<select id='students_selectmenu'>" + optionsHtml + "</select>";

    this.option_index = 0;

    this.selectMenuAccessibilityFixes = function(container){
      var $select_menu = $(container).find("select#students_selectmenu");

      $(container).find("a.ui-selectmenu")
        .removeAttr("role")
        .removeAttr("aria-haspopup")
        .removeAttr("aria-owns")
        .removeAttr("aria-disabled")
        .attr("aria-hidden", true)
        .attr("tabindex", -1)
        .css("margin", 0);

      $select_menu.addClass("screenreader-only")
        .removeAttr("style")
        .removeAttr("aria-disabled")
        .attr("tabindex", 0)
        .show();
    };

    this.focusHandlerAccessibilityFixes = function(container){
      var focus = function(e){
        $(container).find("span.ui-selectmenu-icon").css("background-position", "-17px 0");
      };
      var focusOut = function(e){
        $(container).find("span.ui-selectmenu-icon").css("background-position", "0 0");
      };

      // In case someone mouseovers, let's visual color to match a
      // keyboard focus
      $(container).on("focus", "a.ui-selectmenu", focus);
      $(container).on("focusout", "a.ui-selectmenu", focusOut);

      // Remove the focus binding from jquery that steals away from
      // the select and add our own that doesn't, but still does some
      // visual decoration.
      var $select_menu = $(container).find("select#students_selectmenu");
      $select_menu.unbind('focus');
      $select_menu.bind('focus', focus);
      $select_menu.bind("focusout", focusOut);
    };

    this.keyEventAccessibilityFixes = function(container){
      var self = this;
      var $select_menu = $(container).find("select#students_selectmenu");
      // The fake gui menu won't update in firefox until the select is
      // chosen, to work around this, we force an update on any key
      // press.
      $select_menu.bind("keyup", function(e){
        var code = e.keyCode || e.which;
        if(code == 37 || code == 38 || code == 39 || code == 40) { //left, up, right, down arrow
          self.jquerySelectMenu().change();
        }
      });
    }

    this.accessibilityFixes = function(container){
      this.focusHandlerAccessibilityFixes(container);
      this.selectMenuAccessibilityFixes(container);
      this.keyEventAccessibilityFixes(container);
    };

    this.appendTo = function(selector, onChange){
      var self = this;
      this.$el = $(this.html).appendTo(selector).selectmenu({
        style:'dropdown',
        format: function(text){
          return self.formatSelectText(text);
        },
        open: function(event){
          self.our_open(event);
        }
      });
      this.$el.change(onChange);
      this.accessibilityFixes(this.$el.parent());
      this.replaceDropdownIcon(this.$el.parent());
    };

    this.replaceDropdownIcon = function(container){
      var $span = $(container).find("span.ui-selectmenu-icon");
      $span.removeClass("ui-icon");
      $("<i class='icon-mini-arrow-down'></i>").appendTo($span);
    };

    this.jquerySelectMenu = function(){
      return this.$el;
    };

    this.our_open = function(event){
      this.accessibilityFixes(this.$el.parent());
    };

    // xsslint safeString.function getIcon
    this.getIconHtml = function(helper_text){
      var icon =
          "<span class='ui-selectmenu-item-icon speedgrader-selectmenu-icon'>";
      if(helper_text === "graded"){
        icon += "<i class='icon-check'></i>";
      }else if(["not_graded", "resubmitted"].indexOf(helper_text) !== -1){
        // This is the UTF-8 code for "Black Circle"
        icon += "&#9679;";
      }
      return icon.concat("</span>");
    };

    this.formatSelectText = function(text){
      var parts = text.split(delimiter);

      $($("#students_selectmenu > option")[this.option_index])
        .text(htmlEscape(parts[0]) + " - " + htmlEscape(parts[1]));

      this.option_index++;

      return this.getIconHtml(htmlEscape(parts[2])) +
        '<span class="ui-selectmenu-item-header">' +
        htmlEscape(parts[0]) +
        '</span>';
    };
  };

  return speedgraderSelectMenu;
});
