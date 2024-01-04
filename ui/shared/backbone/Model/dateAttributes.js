//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'backbone'
import {each} from 'lodash'

const _parse = Backbone.Model.prototype.parse

Backbone.Model.prototype.parse = function () {
  const res = _parse.apply(this, arguments)

  each(this.dateAttributes, attr => {
    if (res[attr]) res[attr] = Date.parse(res[attr])
  })
  return res
}

export default Backbone.Model
