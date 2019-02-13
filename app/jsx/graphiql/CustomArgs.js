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

import GraphiQLExplorer from 'graphiql-explorer';

// makeDefaultArg and getDefulatScalarArgValue
// are used to fill in the default argument for
// fields that require one. To see a more complete
// implementation, should we decide to do something
// more deluxe, see
// https://github.com/OneGraph/graphiql-explorer-example/blob/master/src/CustomArgs.js

export function makeDefaultArg(_parentField, _arg) {
  return false;
}

export function getDefaultScalarArgValue(parentField, arg, argType) {
  // so there's a good chance we get something, or nothing,
  // but probably not an error
  if (argType.name === 'ID') {
    return {kind: 'StringValue', value: '1'}
  }
  return GraphiQLExplorer.defaultValue(argType);
}
