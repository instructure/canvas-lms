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

import I18n from 'i18n!account_settings'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import template from 'jst/feature_flags/featureFlagAdminView'
import FeatureFlagCollection from '../../collections/FeatureFlagCollection'
import FeatureFlagListView from './FeatureFlagListView'

export default class FeatureFlagAdminView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.default = {
      account: [],
      rootaccount: [],
      course: [],
      user: []
    }

    this.prototype.els = {'.alert': '$alertBox'}

    this.prototype.featureGroups = ['account', 'course', 'user']

    this.prototype.titles = {
      account: I18n.t('account', 'Account'),
      course: I18n.t('course', 'Course'),
      user: I18n.t('user', 'User')
    }
  }

  constructor() {
    super(...arguments)
    this.collection = new FeatureFlagCollection()
    this.attachEvents()
  }

  attachEvents() {
    return this.collection.on('finish', this.onSync.bind(this))
  }

  onSync(collection, response, xhr) {
    // only listen for the first sync event; others are updates to existing flags
    this.collection.off('sync')
    return this.render()
  }

  shouldShowTitles(features) {
    const counts = _.map(this.featureGroups, key => features[key].length)
    return _.reject(counts, count => count === 0).length > 1
  }

  render() {
    super.render(...arguments)
    if (this.collection.length) {
      this.$alertBox.hide()
    } else {
      this.$alertBox.show()
    }
    const features = _.extend({}, this.default, this.collection.groupBy('appliesTo'))
    features.account = features.account.concat(features.rootaccount)
    return _.each(this.featureGroups, group => {
      if (!(features[group] != null ? features[group].length : undefined)) return
      if (this.options.hiddenFlags != null ? this.options.hiddenFlags.length : undefined) {
        features[group] = features[group].filter(
          flag => !this.options.hiddenFlags.includes(flag.get('feature'))
        )
      }
      const title = this.shouldShowTitles(features) ? this.titles[group] : null
      const view = new FeatureFlagListView({
        collection: new Backbone.Collection(features[group]),
        el: $(`.${group}-feature-flags`),
        title
      })
      view.render()
    })
  }
}
FeatureFlagAdminView.initClass()
