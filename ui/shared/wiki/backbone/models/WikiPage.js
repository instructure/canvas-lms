//
// Copyright (C) 2013 - present Instructure, Inc.
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
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import $ from 'jquery'
import {pick, omit} from 'lodash'
import Backbone from '@canvas/backbone'
import WikiPageRevision from './WikiPageRevision'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'
import splitAssetString from '@canvas/util/splitAssetString'
import {useScope as useI18nScope} from '@canvas/i18n'

let WikiPage

const I18n = useI18nScope('pages')

const pageOptions = ['contextAssetString', 'revision']

export default WikiPage = (function () {
  WikiPage = class WikiPage extends Backbone.Model {
    static initClass() {
      this.mixin(DefaultUrlMixin)
      this.prototype.resourceName = 'pages'
      this.prototype.idAttribute = 'page_id'
    }

    initialize(attributes, options) {
      super.initialize(...arguments)
      Object.assign(this, pick(options || {}, pageOptions))
      if (this.contextAssetString) {
        ;[this.contextName, this.contextId] = Array.from(splitAssetString(this.contextAssetString))
      }

      this.on('change:front_page', this.setPublishable)
      this.on('change:published', this.setPublishable)
      return this.setPublishable()
    }

    setPublishable() {
      const front_page = this.get('front_page')
      const published = this.get('published')
      const publishable = !front_page || !published
      const deletable = !front_page
      this.set('publishable', publishable)
      this.set('deletable', deletable)
      if (publishable) {
        return this.unset('publishableMessage')
      } else {
        return this.set(
          'publishableMessage',
          I18n.t('cannot_unpublish_front_page', 'Cannot unpublish the front page')
        )
      }
    }

    disabledMessage() {
      return this.get('publishableMessage')
    }

    urlRoot() {
      return `/api/v1/${this._contextPath()}/pages`
    }

    url() {
      if (this.get('url')) {
        return `${this.urlRoot()}/${this.get('url')}`
      } else {
        return this.urlRoot()
      }
    }

    latestRevision(options) {
      if (!this._latestRevision && this.get('url')) {
        if (!this._latestRevision) {
          const revisionOptions = {
            contextAssetString: this.contextAssetString,
            page: this,
            pageUrl: this.get('url'),
            latest: true,
            summary: true,
            ...options,
          }
          this._latestRevision = new WikiPageRevision({revision_id: this.revision}, revisionOptions)
        }
      }
      return this._latestRevision
    }

    // Flatten the nested data structure required by the api (see @publish and @unpublish)
    parse(response, _options) {
      if (response.wiki_page) {
        response = {
          ...omit(response, 'wiki_page'),
          ...response.wiki_page,
        }
      }
      response.set_assignment =
        response.assignment != null && response.assignment.only_visible_to_overrides
      const assign_attributes = response.assignment || {}
      response.assignment = this.createAssignment(assign_attributes)
      return response
    }

    createAssignment(attributes) {
      const a = new Assignment(attributes)
      a.alreadyScoped = true
      return a
    }

    // Gives a json representation of the model
    toJSON() {
      const json = super.toJSON(...arguments)
      if (!json.set_assignment) {
        delete json.assignment
      }
      json.assignment = json.assignment != null ? json.assignment.toJSON() : undefined

      return {
        wiki_page: json,
      }
    }

    // Returns a json representation suitable for presenting
    present() {
      return {
        ...this.attributes,
        contextName: this.contextName,
        contextId: this.contextId,
        new_record: !this.get('url'),
      }
    }

    duplicate(courseId, callback) {
      return $.ajaxJSON(
        `/api/v1/courses/${courseId}/pages/${this.id}/duplicate`,
        'POST',
        {},
        callback
      )
    }

    // Uses the api to perform a publish on the page
    publish() {
      const attrs = {
        wiki_page: {
          published: true,
        },
      }
      return this.save(attrs, {attrs, wait: true})
    }

    // Uses the api to perform an unpublish on the page
    unpublish() {
      const attrs = {
        wiki_page: {
          published: false,
        },
      }
      return this.save(attrs, {attrs, wait: true})
    }

    // Uses the api to set the page as the front page
    setFrontPage(callback) {
      const attrs = {
        wiki_page: {
          front_page: true,
        },
      }
      return this.save(attrs, {attrs, wait: true, complete: callback})
    }

    // Uses the api to unset the page as the front page
    unsetFrontPage() {
      const attrs = {
        wiki_page: {
          front_page: false,
        },
      }
      return this.save(attrs, {attrs, wait: true})
    }
  }
  WikiPage.initClass()
  return WikiPage
})()
