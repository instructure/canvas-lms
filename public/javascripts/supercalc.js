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
  'i18n!calculator',
  'jquery' /* $ */,
  'calcCmd',
  'str/htmlEscape',
  'jquery.instructure_misc_helpers' /* /\$\.raw/ */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jqueryui/sortable' /* /\.sortable/ */
], function(I18n, $, calcCmd, htmlEscape) {

  var generateFinds = function($table) {
    var finds = {};
    finds.formula_rows = $table.find(".formula_row");
    finds.formula_rows.each(function(i) {
      this.formula = $(this).find(".formula");
      this.status = $(this).find(".status");
      $(this).data('formula', $(this).find(".formula"));
      $(this).data('status', $(this).find(".status"));
    });
    finds.round = $table.find(".round");
    finds.status = $table.find(".status");
    finds.last_row_details = $table.find(".last_row_details");
    return finds;
  };
  $.fn.superCalc = function(options, more_options) {
    if(options == 'recalculate') {
      $(this).triggerHandler('calculate', more_options);
    } else if(options == 'clear') {
      calcCmd.clearMemory();
    } else if(options == 'cache_finds') {
      $(this).data('cached_finds', generateFinds($(this).data('table')));
    } else if(options == 'clear_cached_finds') {
      $(this).data('cached_finds', null);
    } else {
      options = options || {};
      options.c1 = true;
      var $entryBox = $(this);
      var $table = $("<table class='formulas' aria-live='polite'>" +
                        "<thead><tr><td id='headings.formula'>" + htmlEscape(I18n.t('headings.formula', "Formula")) + "</td><td id='headings.result'>" + htmlEscape(I18n.t('headings.result', "Result")) + "</td><td aria-hidden='true'>&nbsp;</td></tr></thead>" +
                        "<tfoot>" +
                          "<tr><td colspan='3' class='last_row_details' style='display: none;'>" + htmlEscape(I18n.t('last_formula_row', "the last formula row will be used to compute the final answer")) + "</td></tr>" +
                          "<tr><td></td><td class='decimal_places'>" +
                            "<select aria-labelledby='decimal_places_label' class='round'><option>0</option><option>1</option><option>2</option><option>3</option><option>4</option></select> " +
                            "<label id='decimal_places_label'>" + htmlEscape(I18n.t('decimal_places', 'Decimal Places')) + "</label>" +
                          "</td></tr>" +
                        "</tfoot>" +
                        "<tbody></tbody>"+
                      "</table>");

      $entryBox.attr('aria-labelledby', 'headings.formula');
      $entryBox.css('width', '220px');
      $(this).data('table', $table);
      $entryBox.before($table);
      $table.find("tfoot tr:last td:first").append($entryBox);
      var $displayBox = $entryBox.clone(true).removeAttr('id');
      $table.find("tfoot tr:last td:first").append($displayBox);
      var $enter = $("<button type='button' class='btn save_formula_button'>" + htmlEscape(I18n.t('buttons.save', "Save")) + "</button>");
      $table.find("tfoot tr:last td:first").append($enter);
      $entryBox.hide();
      var $input = $("<input type='text' readonly='true'/>");
      $table.find("tfoot tr:last td:first").append($input.hide());
      $entryBox.data('supercalc_options', options);
      $entryBox.data('supercalc_answer', $input);
      $table.delegate('.save_formula_button', 'click', function() {
        $displayBox.triggerHandler('keypress', true);
      });
      $table.delegate('.delete_formula_row_link', 'click', function(event) {
        event.preventDefault();
        $(event.target).parents("tr").remove();
        $entryBox.triggerHandler('calculate');
      });
      $table.find("tbody").sortable({
        items: '.formula_row',
        update: function() {
          $entryBox.triggerHandler('calculate');
        }
      });
      $table.delegate('.round', 'change', function() {
        $entryBox.triggerHandler('calculate');
      });
      $entryBox.bind('calculate', function(event, no_dom) {
        calcCmd.clearMemory();
        var finds = $(this).data('cached_finds') || generateFinds($table);
        if(options.pre_process && $.isFunction(options.pre_process)) {
          var lines = options.pre_process();
          for(var idx in lines) {
            if(!no_dom) {
              $entryBox.val(lines[idx] || "");
            }
            try {
              calcCmd.compute(lines[idx]);
            } catch(e) {
            }
          }
        }
        finds.formula_rows.each(function() {
          var formula_text = this.formula.html();
          $entryBox.val(formula_text);
          var res = null;
          try {
            // precision 15 to strip floating point error
            var precision = 15;
            // regex strips extra 0s from toPrecision output
            var stripZeros = function(str){return str.replace(/(?:(\.[0-9]*[^0e])|\.)0*(e.*)?$/,"$1$2")};

            var val = +calcCmd.computeValue(formula_text).toPrecision(precision);
            var rounder = Math.pow(10, parseInt(finds.round.val(), 10) || 0) || 1;
            res = "= " + stripZeros((Math.round(val * rounder) / rounder).toPrecision(precision));
          } catch(e) {
            res = e.toString();
          }
          this.status.attr('data-res', res);
          if(!no_dom) {
            this.status.text(res);
          }
        });
        if(!no_dom) {
          if(finds.formula_rows.length > 1) {
            finds.formula_rows.removeClass('last_row').filter(":last").addClass('last_row');
          }
          finds.last_row_details.showIf(finds.formula_rows.length > 1);
          finds.status.removeAttr('title').filter(":last").attr('title', I18n.t('sample_final_answer', 'This value is an example final answer for this question type'));
          $entryBox.val("");
        }
      });
      $displayBox.bind('keypress', function(event, enter) {
        $entryBox.val($displayBox.val());
        if(event.keyCode == 13 || enter && $displayBox.val()) {
          event.preventDefault();
          event.stopPropagation();
          var $tr = $("<tr class='formula_row'><td class='formula' aria-labelledby='headings.formula' title='" + htmlEscape(I18n.t('drag_to_reorder', 'Drag to reorder')) + "'></td><td class='status' aria-labelledby='headings.result'></td><td><a href='#' class='delete_formula_row_link no-hover'><img src='/images/delete_circle.png' alt='" + htmlEscape(I18n.t('delete_formula', 'Delete Formula')) + "'/></a></td></tr>");
          $tr.find("td:first").text($entryBox.val());
          $entryBox.val("");
          $displayBox.val("");
          $table.find("tbody").append($tr);
          $entryBox.triggerHandler('calculate');
          $displayBox.focus();
          if(options && options.formula_added && $.isFunction(options.formula_added)) {
            options.formula_added.call($entryBox);
          }
        }
      });
    }
  };
});
