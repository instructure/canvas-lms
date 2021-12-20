/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
export const RECEIVE_SESSION = 'action.session.receive_session';

function receiveSession(data) {
  return {
    type: RECEIVE_SESSION,
    data
  };
}

export function get(dispatch, getState) {
  var _source$getSession;

  const _getState = getState(),
        source = _getState.source;

  return (_source$getSession = source.getSession) === null || _source$getSession === void 0 ? void 0 : _source$getSession.call(source).then(data => dispatch(receiveSession(data)));
}