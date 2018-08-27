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

import _ from 'underscore'
import createStore from '../helpers/createStore'
import $ from 'jquery'
  var ProgressStore = createStore({}),
    _progresses = {};

  ProgressStore.get = function(progress_id) {
    var url = "/api/v1/progress/" + progress_id;

    $.getJSON(url, function(data) {
      _progresses[data.id] = data;
      ProgressStore.setState(_progresses);
    });
  };

export default ProgressStore
