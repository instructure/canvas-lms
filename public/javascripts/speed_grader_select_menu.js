/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery';
import 'vendor/ui.selectmenu';
import htmlEscape from './str/htmlEscape';

function optionsToHtml (optionDefinitions) {
  return optionDefinitions.map((optionDef) => {
    let html = '';

    if (optionDef.options) {
      // This is an optgroup
      const childrenHtml = optionsToHtml(optionDef.options);
      html = `
        <optgroup label="${htmlEscape(optionDef.name)}">
            ${childrenHtml}
        </optgroup>
      `;
    } else {
      const labels = [
        optionDef.name,
      ]

      if (optionDef.className && optionDef.className.formatted) {
        labels.push(optionDef.className.formatted);
      }

      html = `
        <option value="${htmlEscape(optionDef.id)}" class="${htmlEscape(optionDef.className.raw)} ui-selectmenu-hasIcon">
            ${htmlEscape(labels.join(' - '))}
        </option>
      `;
    }

    return html;
  }).join('');
}

export default function speedgraderSelectMenu (optionsArray) {
  // Array of the initial data needed to build the select menu
  this.options_array = optionsArray;

  // Index used by text formatting function
  this.option_index = 0;
  this.opt_group_found = false;
  this.option_sub_index = 0;

  // Array for the generated option tags
  this.option_tag_array = null;

  this.buildHtml = function (options) {
    const optionHtml = optionsToHtml(options);

    return `<select id='students_selectmenu'>${optionHtml}</select>`;
  };

  this.selectMenuAccessibilityFixes = function (container) {
    const $select_menu = $(container).find('select#students_selectmenu');

    $(container).find('a.ui-selectmenu')
      .removeAttr('role')
      .removeAttr('aria-haspopup')
      .removeAttr('aria-owns')
      .removeAttr('aria-disabled')
      .attr('aria-hidden', true)
      .attr('tabindex', -1)
      .css('margin', 0);

    $select_menu.addClass('screenreader-only')
      .removeAttr('style')
      .removeAttr('aria-disabled')
      .attr('tabindex', 0)
      .show();
  };

  this.focusHandlerAccessibilityFixes = function (container) {
    const focus = function (_e) {
      $(container).find('span.ui-selectmenu-icon').css('background-position', '-17px 0');
    };
    const focusOut = function (_e) {
      $(container).find('span.ui-selectmenu-icon').css('background-position', '0 0');
    };

    // In case someone mouseovers, let's visual color to match a
    // keyboard focus
    $(container).on('focus', 'a.ui-selectmenu', focus);
    $(container).on('focusout', 'a.ui-selectmenu', focusOut);

    // Remove the focus binding from jquery that steals away from
    // the select and add our own that doesn't, but still does some
    // visual decoration.
    const $select_menu = $(container).find('select#students_selectmenu');
    $select_menu.unbind('focus');
    $select_menu.bind('focus', focus);
    $select_menu.bind('focusout', focusOut);
  };

  this.keyEventAccessibilityFixes = function (container) {
    const self = this;
    const $select_menu = $(container).find('select#students_selectmenu');
    // The fake gui menu won't update in firefox until the select is
    // chosen, to work around this, we force an update on any key
    // press.
    $select_menu.bind('keyup', (e) => {
      const code = e.keyCode || e.which;
      if (code === 37 || code === 38 || code === 39 || code === 40) { // left, up, right, down arrow
        self.jquerySelectMenu().change();
      }
    });
  };

  this.accessibilityFixes = function (container) {
    this.focusHandlerAccessibilityFixes(container);
    this.selectMenuAccessibilityFixes(container);
    this.keyEventAccessibilityFixes(container);
  };

  this.appendTo = function (selector, onChange) {
    const self = this;
    this.$el = $(this.buildHtml(this.options_array)).appendTo(selector).selectmenu({
      style: 'dropdown',
      format: text => (
        self.formatSelectText(text)
      ),
      open: (event) => {
        self.our_open(event);
      }
    });
    // Remove the section change optgroup since it'll be replaced by a popout menu
    $('ul#students_selectmenu-menu li.ui-selectmenu-group').remove()

    // Create indexes into what we've created because we'll want them later
    this.option_tag_array = $('#students_selectmenu > option');

    this.$el.change(onChange);
    this.accessibilityFixes(this.$el.parent());
    this.replaceDropdownIcon(this.$el.parent());
  };

  this.replaceDropdownIcon = function (container) {
    const $span = $(container).find('span.ui-selectmenu-icon');
    $span.removeClass('ui-icon');
    $("<i class='icon-mini-arrow-down'></i>").appendTo($span);
  };

  this.jquerySelectMenu = function () {
    return this.$el;
  };

  this.our_open = function (_event) {
    this.accessibilityFixes(this.$el.parent());
  };

  // xsslint safeString.function getIcon
  this.getIconHtml = function (helper_text) {
    let icon =
      "<span class='ui-selectmenu-item-icon speedgrader-selectmenu-icon'>";
    if (helper_text === 'graded') {
      icon += "<i class='icon-check'></i>";
    } else if (['not_graded', 'resubmitted'].indexOf(helper_text) !== -1) {
      // This is the UTF-8 code for "Black Circle"
      icon += '&#9679;';
    }
    return icon.concat('</span>');
  };

  this.formatSelectText = function (_text) {
    let option = this.options_array[this.option_index];
    let optgroup;
    let html = '';

    if (option.options) {
      optgroup = option;

      if (!this.opt_group_found) {
        // We encountered this optgroup but haven't start traversing it yet
        this.opt_group_found = true;
        this.option_sub_index = 0;
        option = optgroup.options[this.option_sub_index];
      }

      if (this.opt_group_found && this.option_sub_index < optgroup.options.length) {
        // We're still traversing this optgroup, carry on
        option = optgroup.options[this.option_sub_index];

        this.option_sub_index++;
      } else {
        this.opt_group_found = false;
        this.option_sub_index = 0;
        this.option_index++;

        option = this.options_array[this.option_index]
        this.option_index++;
      }
    } else {
      this.opt_group_found = false;
      this.option_sub_index = 0;
      this.option_index++;
    }

    if (option.options) {
      html = htmlEscape(option.name);
    }

    return `
        ${html}
        ${this.getIconHtml(htmlEscape(option.className.raw))}
        <span class="ui-selectmenu-item-header">
            ${htmlEscape(option.name)}
        </span>
    `;
  };
}
