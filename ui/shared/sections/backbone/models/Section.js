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
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import {Model} from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'

let Section

const I18n = useI18nScope('modelsSection')

export default Section = (function () {
  Section = class Section extends Model {
    constructor(...args) {
      super(...args)
      this.isDefaultDueDateSection = this.isDefaultDueDateSection.bind(this)
    }

    static initClass() {
      this.defaultDueDateSectionID = '0'
    }

    static defaultDueDateSection() {
      return new Section({
        id: Section.defaultDueDateSectionID,
        name: I18n.t('overrides.everyone', 'Everyone'),
      })
    }

    isDefaultDueDateSection() {
      return this.id === Section.defaultDueDateSectionID
    }
  }
  Section.initClass()
  return Section
})()
