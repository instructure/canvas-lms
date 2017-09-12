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

import Gradebook from 'compiled/gradezilla/Gradebook';

export function createGradebook (options = {}) {
  const gradebook = new Gradebook({
    colors: {},
    context_id: '1',
    new_gradebook_development_enabled: true,
    locale: 'en',
    post_grades_ltis: [],
    sections: [],
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'false'
    },
    ...options
  });
  gradebook.keyboardNav = {
    addGradebookElement () {},
    removeGradebookElement () {}
  };

  return gradebook;
}

export default {
  createGradebook
};
