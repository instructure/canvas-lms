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
  'i18n!plugins',
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* showIf */
], function(I18n, $) {

  $(document).ready(function () {
    $('#recordings_enabled_checkbox').change(function () {
      $("#recording_feature_options").showIf($(this).attr('checked'));
      $("#recording_option_enabled").showIf($(this).attr('checked'));
    }).change();

    $('#recording_option_enabled').showIf(
      $('#recordings_enabled_checkbox').attr('checked') && $('#settings_recording_options').val() === '1'
    );
    displayLegend($('#settings_recording_options'));

    $('#settings_recording_options').change(function () {
      displayLegend(this);
      $('#recording_option_enabled').showIf($(this).val() === '1');
    })
  });

  function displayLegend(element) {
    var option = $(element).val();
    var text;

    switch (option) {
      case '1':
        text = I18n.t("conferences.bigbluebutton.legend_default", "Instructor can use Start/Stop Record button in sessions configured for recording.");
        break;
      case '2':
        text = I18n.t("conferences.bigbluebutton.legend_all", "Instructor can use Start/Stop Record button in all sessions.");
        break;
      case '3':
        text = I18n.t("conferences.bigbluebutton.legend_hide", "Hide Start/Stop Record button. Record all content shared in every session.");
        break;
      default:
        text = "";
    }

    if ($(document).has('#recording_option_legend').length > 0) {
      $(document).find('#recording_option_legend').remove();
    }

    $('<small class="help-text" id="recording_option_legend"><br>' + htmlEscape(text) + '</small>').insertAfter(element);
  }
});
