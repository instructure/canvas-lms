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
import SpeedgraderHelpers from 'speed_grader_helpers';
import htmlEscape from './str/htmlEscape';

function optionsToHtml (optionDefinitions) {
  return optionDefinitions.map((definition) => {
    let html = '';

    if (definition.options) {
      const childrenHtml = optionsToHtml(definition.options);
      html = `
        <optgroup label="${htmlEscape(definition.name)}">
          ${childrenHtml}
        </optgroup>
      `;
    } else {
      if (definition.anonymizableId == null) {
        throw Error('`anonymizableId` required in optionDefinition objects')
      }
      const labels = [definition.name]

      if (definition.className && definition.className.formatted) {
        labels.push(definition.className.formatted);
      }

      html = `
        <option
          value="${htmlEscape(definition[definition.anonymizableId])}"
          class="${htmlEscape(definition.className.raw)} ui-selectmenu-hasIcon"
        >
          ${htmlEscape(labels.join(' – '))}
        </option>
      `;
    }

    return html;
  }).join('');
}

function buildStudentIdMap (optionDefinitions) {
  const studentMap =  {};
  let adjust = 0;
  optionDefinitions.forEach((optionDefinition, index) => {
    if (optionDefinition.options) {
      // There should only ever be one, but just in case
      adjust += 1;
    }
    else {
      studentMap[optionDefinition[optionDefinition.anonymizableId]] = index - adjust;
    }
  });
  return studentMap;
};

export default function speedgraderSelectMenu (optionsArray) {
  // Array of the initial data needed to build the select menu
  this.options_array = optionsArray;

  // Index used by text formatting function
  this.option_index = 0;
  this.opt_group_found = false;
  this.option_sub_index = 0;

  // Array for the generated option tags
  this.option_tag_array = null;

  // Map of student id to index position
  this.student_id_map = null;

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
        self.$el.change();
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
    this.student_id_map = buildStudentIdMap(this.options_array);
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
    $('ul#students_selectmenu-menu li.ui-selectmenu-group').remove();

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

  // The following 4 functions just delegate to the contained component.
  this.val = (...args) => (this.$el.val(...args));
  this.data = (...args) => (this.$el.data(...args));
  this.selectmenu = (...args) => (this.$el.selectmenu(...args));
  this.change = (...args) => (this.$el.change(...args));

  this.our_open = (_event) => {
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

  this.updateSelectMenuStatus = function ({student, isCurrentStudent, newStudentInfo, anonymizableId}) {
    if (!student) return;
    const optionIndex = this.student_id_map[student[anonymizableId]];
    let $query = this.$el.data('selectmenu').list.find(`li:eq(${optionIndex})`);
    const className = SpeedgraderHelpers.classNameBasedOnStudent(student);
    const submissionStates = 'not_graded not_submitted graded resubmitted';

    if (isCurrentStudent) {
      $query = $query.add(this.$el.data('selectmenu').newelement);
    }
    $query
      .removeClass(submissionStates)
      .addClass(className.raw);

    const $status = $('.ui-selectmenu-status');
    const $statusIcon = $status.find('.speedgrader-selectmenu-icon');
    const $queryIcon = $query.find('.speedgrader-selectmenu-icon');

    const option = $(this.option_tag_array[optionIndex]);
    option.text(newStudentInfo).removeClass(submissionStates).addClass(className.raw);

    if(className.raw === "graded" || className.raw === "not_gradeable"){
      $queryIcon.text("").append("<i class='icon-check'></i>");
      if (isCurrentStudent) {
        $status.addClass("graded");
        $statusIcon.text("").append("<i class='icon-check'></i>");
      }
    }else if(className.raw === "not_graded"){
      $queryIcon.text("").append("&#9679;");
      if (isCurrentStudent) {
        $status.removeClass("graded");
        $statusIcon.text("").append("&#9679;");
      }
    }else{
      $queryIcon.text("");
      if (isCurrentStudent) {
        $status.removeClass("graded");
        $statusIcon.text("");
      }
    }

    // this is because selectmenu.js uses .data('optionClasses' on the
    // li to keep track of what class to put on the selected option (
    // aka: $selectmenu.data('selectmenu').newelement ) when this li
    // is selected.  so even though we set the class of the li and the
    // $selectmenu.data('selectmenu').newelement when it is graded, we
    // need to also set the data() so that if you skip back to this
    // student it doesnt show the old checkbox status.
    $.each(submissionStates.split(' '), function(){
      $query.data('optionClasses', $query.data('optionClasses').replace(this, ''));
    });
  };
}
