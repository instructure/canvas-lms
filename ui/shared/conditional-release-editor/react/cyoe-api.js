/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import parseLinkHeader from '@canvas/parse-link-header'
import numberHelper from '@canvas/i18n/numberHelper'

import categories, {OTHER_ID} from './categories'

// in general, these methods return promises
const CyoeApi = {
  getRuleForAssignment: state => {
    const courseId = state.get('course_id')
    const triggerAssignmentId = state.getIn(['trigger_assignment', 'id'])
    if (triggerAssignmentId) {
      return axios
        .get(`/api/v1/courses/${courseId}/mastery_paths/rules`, {
          params: {
            trigger_assignment_id: triggerAssignmentId,
            include: ['all'],
          },
        })
        .then(res => {
          res.data = res.data.length ? res.data[0] : null
          return res
        })
    } else {
      return Promise.resolve({data: null})
    }
  },

  saveRule: state => {
    const courseId = state.get('course_id')
    let url = `/api/v1/courses/${courseId}/mastery_paths/rules`

    const data = state.get('rule').toJS()
    CyoeApi._parseBounds(data) // convert localized bounds (with possible decimal commas etc.) to numbers
    const ruleId = state.getIn(['rule', 'id'])
    const triggerId = state.getIn(['trigger_assignment', 'id'])

    if (ruleId) {
      url = `/api/v1/courses/${courseId}/mastery_paths/rules/${ruleId}`
      return axios.put(url, data)
    } else if (data.scoring_ranges) {
      // don't create an empty rule
      const shouldSaveRule = data.scoring_ranges.find(range => {
        return range.assignment_sets.find(set => {
          return set.assignment_set_associations.length > 0
        })
      })
      if (shouldSaveRule) {
        data.trigger_assignment_id = triggerId
        data.scoring_ranges = data.scoring_ranges.map(range => {
          delete range.id
          return range
        })
        return axios.post(url, data)
      } else {
        return Promise.resolve({data})
      }
    }
  },

  deleteRule: state => {
    const courseId = state.get('course_id')
    const ruleId = state.getIn(['rule', 'id'])
    if (ruleId) {
      const url = `/api/v1/courses/${courseId}/mastery_paths/rules/${ruleId}`
      return axios.delete(url)
    } else {
      return Promise.resolve({})
    }
  },

  getAssignments: state => {
    const perPage = 100
    return CyoeApi._depaginate(
      `/api/v1/courses/${state.get('course_id')}/assignments?per_page=${perPage}`
    ).then(res => {
      res.data.forEach(CyoeApi._assignCategory)
      return res
    })
  },

  _assignCategory: asg => {
    const category = categories.find(cat => {
      return (
        asg.submission_types.length &&
        cat.submission_types &&
        asg.submission_types.find(sub => cat.submission_types.includes(sub))
      )
    })
    asg.category = category ? category.id : OTHER_ID
  },

  _depaginate: (url, allResults = []) => {
    return axios.get(url).then(res => {
      allResults = allResults.concat(res.data)
      if (res.headers.link) {
        const links = parseLinkHeader(res.headers.link)
        if (links.next) {
          return CyoeApi._depaginate(links.next.url, allResults)
        }
      }
      res.data = allResults
      return res
    })
  },

  _parseBounds: data => {
    data.scoring_ranges.forEach(range => {
      if (typeof range.lower_bound === 'string') {
        range.lower_bound = numberHelper.parse(range.lower_bound)
      }
      if (typeof range.upper_bound === 'string') {
        range.upper_bound = numberHelper.parse(range.upper_bound)
      }
    })
  },
}

export default CyoeApi
