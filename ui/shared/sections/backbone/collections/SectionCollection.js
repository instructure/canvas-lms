//
// Copyright (C) 2011 - present Instructure, Inc.
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
//

import {Collection} from '@canvas/backbone'
import Section from '../models/Section.coffee'

// A collection for working with course sections returned from
// CoursesController#sections.
export default class SectionCollection extends Collection {
  ids = () => this.pluck('id')

  comparator(section) {
    return section.id
  }
}
SectionCollection.prototype.model = Section
