/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import * as HistoryActions from '../../gradebook-history/actions/HistoryActions';
import HistoryApi from '../../gradebook-history/api/HistoryApi';

export function getHistoryNextPage (url) {
  return function (dispatch) {
    dispatch(HistoryActions.fetchHistoryNextPageStart());

    return HistoryApi.getNextPage(url)
      .then((response) => {
        dispatch(HistoryActions.fetchHistoryNextPageSuccess(response.data, response.headers));
      })
      .catch(() => {
        dispatch(HistoryActions.fetchHistoryNextPageFailure());
      });
  };
}