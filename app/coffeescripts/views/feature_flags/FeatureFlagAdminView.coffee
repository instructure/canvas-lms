#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!account_settings'
  'jquery'
  'underscore'
  'Backbone'
  'jst/feature_flags/featureFlagAdminView'
  '../../collections/FeatureFlagCollection'
  '../feature_flags/FeatureFlagListView'
], (I18n, $, _, Backbone, template, FeatureFlagCollection, FeatureFlagListView) ->

  class FeatureFlagAdminView extends Backbone.View

    template: template

    default:
      account:     []
      rootaccount: []
      course:      []
      user:        []

    els:
      '.alert': '$alertBox'

    featureGroups: ['account', 'course', 'user']

    titles:
      account: I18n.t('account', 'Account')
      course:  I18n.t('course',  'Course')
      user:    I18n.t('user',    'User')

    constructor: ->
      super
      @collection = new FeatureFlagCollection
      @attachEvents()

    attachEvents: ->
      @collection.on('finish', @onSync)

    onSync: (collection, response, xhr) =>
      # only listen for the first sync event; others are updates to existing flags
      @collection.off('sync')
      @render()

    shouldShowTitles: (features) ->
      counts = _.map(@featureGroups, (key) -> features[key].length)
      _.reject(counts, (count) -> count == 0).length > 1

    render: ->
      super
      if @collection.length then @$alertBox.hide() else @$alertBox.show()
      features = _.extend({}, @default, @collection.groupBy('appliesTo'))
      features.account = features.account.concat(features.rootaccount)
      _.each(@featureGroups, (group) =>
        return unless features[group]?.length
        if (this.options.hiddenFlags?.length)
          features[group] = features[group].filter((flag) =>
            !this.options.hiddenFlags.includes(flag.get('feature'))
          )
        title = if @shouldShowTitles(features) then @titles[group] else null
        view = new FeatureFlagListView(collection: new Backbone.Collection(features[group]), el: $(".#{group}-feature-flags"), title: title)
        view.render()
      )
