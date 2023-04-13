/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import $ from 'jquery'
import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import template from '../../jst/ProgressBar.handlebars'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('progressbar_view')

extend(ProgressBarView, Backbone.View)

function ProgressBarView() {
  this.initialize = this.initialize.bind(this)
  return ProgressBarView.__super__.constructor.apply(this, arguments)
}

ProgressBarView.prototype.template = template

ProgressBarView.prototype.els = {
  '.progress': '$progress',
}

ProgressBarView.prototype.initialize = function () {
  ProgressBarView.__super__.initialize.apply(this, arguments)
  return this.listenTo(
    this.model,
    'change:completion',
    (function (_this) {
      return function () {
        let ref
        // eslint-disable-next-line no-void
        const integer = Math.floor((ref = _this.model.changed) != null ? ref.completion : void 0)
        const message = I18n.t('Content migration running, %{percent}% complete', {
          percent: integer,
        })
        $.screenReaderFlashMessageExclusive(message)
        return _this.render()
      }
    })(this)
  )
}

ProgressBarView.prototype.toJSON = function () {
  const json = ProgressBarView.__super__.toJSON.apply(this, arguments)
  json.completion = this.model.get('completion')
  return json
}

export default ProgressBarView
