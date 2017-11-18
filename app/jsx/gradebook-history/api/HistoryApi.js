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

import axios from 'axios';

function getGradebookHistory (courseId, input) {
  let url = `/api/v1/audit/grade_change/courses/${courseId}`;
  url += input.assignment ? `/assignments/${input.assignment}` : '';
  url += input.grader ? `/graders/${input.grader}` : '';
  url += input.student ? `/students/${input.student}` : '';

  const params = {
    params: {
      start_time: input.from,
      end_time: input.to,
      include: ['current_grade']
    }
  };

  return axios.get(url, params);
}

function getNextPage (url) {
  return axios.get(url);
}

export default {
  getGradebookHistory,
  getNextPage
};
