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
  'i18n!quizzes.timing',
  'jquery' /* $ */,
  'vendor/date' /* Date.parse */
], function(I18n, $) {

var timing = {
  initialTime: new Date(),
  initTimes: function() {
    if(timing.timesReady) { return timing.clientServerDiff; }
    var serverNow = Date.parse($(".now").text()) || timing.initialTime || new Date();
    var clientNow = timing.initialTime || new Date();
    timing.clientServerDiff = serverNow.getTime() - clientNow.getTime();
    timing.timesReady = true;
  },
  setReferenceDate: function(started_at, end_at, now) {
    if(!timing.timesReady) { timing.initTimes(); }
    var result = {};
    result.referenceDate = Date.parse(end_at);
    result.isDeadline = true;
    $(".time_header").text(I18n.beforeLabel(I18n.t('labels.time_remaining', "Time Remaining")));
    if(!result.referenceDate) {
      result.isDeadline = false;
      $(".time_header").text(I18n.beforeLabel(I18n.t('labels.time_elapsed', "Time Elapsed")));
      result.referenceDate = Date.parse(started_at);
    }
    result.clientServerDiff = timing.clientServerDiff;
    return result;
  }
};

return timing;
});
