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

import _ from 'underscore'
import CollectionView from '../CollectionView'
import FeatureFlagView from '../feature_flags/FeatureFlagView'
import template from 'jst/feature_flags/featureFlagList'

export default class FeatureFlagListView extends CollectionView {
  static initClass() {
    this.prototype.tagName = 'div'

    this.optionProperty('flags')

    this.optionProperty('title')

    this.prototype.template = template

    this.prototype.itemView = FeatureFlagView
  }

  toJSON() {
    return _.extend(super.toJSON(...arguments), {title: this.title})
  }
}
FeatureFlagListView.initClass()
