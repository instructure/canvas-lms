/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var $ = require('jquery');
  var Void = require('canvas_packages/jquery/instructure_date_and_time');

  var exports = {};

  exports.friendlyDatetime = function(dateTime, perspective) {
    var muddledDateTime = dateTime;

    if (muddledDateTime) {
      muddledDateTime.clone = function() {
        return new Date(muddledDateTime.getTime());
      };
    }

    return $.friendlyDatetime(muddledDateTime, perspective);
  };

  exports.fudgeDateForProfileTimezone = $.fudgeDateForProfileTimezone;

  return exports;
});