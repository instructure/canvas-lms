//
// Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'

import {Collection} from '@canvas/backbone'
import Section from '../models/Section'
import Group from '../models/Group'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import WrappedCollection from './WrappedCollection'
import natcompare from '@canvas/util/natcompare'

class GroupCollection extends PaginatedCollection {
  url() {
    return `/api/v1/courses/${this.course_id}/outcome_groups`
  }
}
GroupCollection.optionProperty('course_id')
GroupCollection.prototype.model = Group

class LinkCollection extends PaginatedCollection {
  url() {
    return `/api/v1/courses/${this.course_id}/outcome_group_links?outcome_style=full`
  }
}
LinkCollection.optionProperty('course_id')

class RollupCollection extends WrappedCollection {
  url() {
    return `/api/v1/courses/${this.course_id}/outcome_rollups?user_ids[]=${this.user_id}`
  }
}
RollupCollection.optionProperty('course_id')
RollupCollection.optionProperty('user_id')
RollupCollection.prototype.key = 'rollups'

export default class OutcomeSummaryCollection extends Collection {
  initialize() {
    super.initialize(...arguments)
    this.rawCollections = {
      groups: new GroupCollection([], {course_id: this.course_id}),
      links: new LinkCollection([], {course_id: this.course_id}),
      rollups: new RollupCollection([], {course_id: this.course_id, user_id: this.user_id}),
    }
    return (this.outcomeCache = new Collection())
  }

  fetch = () => {
    const dfd = $.Deferred()
    const requests = Object.values(this.rawCollections).map(collection => {
      collection.loadAll = true
      return collection.fetch()
    })
    $.when(...requests).done(() => this.processCollections(dfd))
    return dfd
  }

  rollups() {
    const studentRollups = this.rawCollections.rollups.at(0).get('scores')
    return Object.fromEntries(studentRollups.map(x => [x.links.outcome, x]))
  }

  populateGroupOutcomes() {
    const rollups = this.rollups()
    this.outcomeCache.reset()
    this.rawCollections.links.each(link => {
      const outcome = new Outcome(link.get('outcome'))
      const parent = this.rawCollections.groups.get(link.get('outcome_group').id)
      const rollup = rollups[outcome.id]
      outcome.set('score', rollup != null ? rollup.score : undefined)
      outcome.set('result_title', rollup != null ? rollup.title : undefined)
      outcome.set('submission_time', rollup != null ? rollup.submitted_at : undefined)
      outcome.set('count', (rollup != null ? rollup.count : undefined) || 0)
      outcome.group = parent
      parent.get('outcomes').add(outcome)
      this.outcomeCache.add(outcome)
    })
  }

  populateSectionGroups() {
    const tmp = new Collection()
    this.rawCollections.groups.each(group => {
      let parent
      if (!group.get('outcomes').length) return
      const parentObj = group.get('parent_outcome_group')
      const parentId = parentObj ? parentObj.id : group.id
      if (!(parent = tmp.get(parentId))) {
        parent = tmp.add(new Section({id: parentId, path: this.getPath(parentId)}))
      }
      parent.get('groups').add(group)
    })
    return this.reset(tmp.models)
  }

  processCollections(dfd) {
    this.populateGroupOutcomes()
    this.populateSectionGroups()
    return dfd.resolve(this.models)
  }

  getPath(id) {
    const group = this.rawCollections.groups.get(id)
    const parent = group.get('parent_outcome_group')
    if (!parent) return ''
    const parentPath = this.getPath(parent.id)
    return (parentPath ? `${parentPath}: ` : '') + group.get('title')
  }
}

OutcomeSummaryCollection.optionProperty('course_id')
OutcomeSummaryCollection.optionProperty('user_id')

OutcomeSummaryCollection.prototype.comparator = natcompare.byGet('path')
