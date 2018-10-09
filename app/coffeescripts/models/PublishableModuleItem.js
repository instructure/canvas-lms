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

import {Model} from 'Backbone'
import I18n from 'i18n!publishableModuleItem'

// A slightly terrible class that branches the urls and json data for the
// different module types
export default class PublishableModuleItem extends Model {
  static initClass() {
    this.prototype.defaults = {
      module_type: null,
      course_id: null,
      module_id: null,
      published: true,
      publishable: true,
      unpublishable: true,
      module_item_name: null
    }

    this.prototype.urls = {
      generic() {
        return `${this.baseUrl()}/modules/${this.get('module_id')}/items/${this.get(
          'module_item_id'
        )}`
      },
      module() {
        return `${this.baseUrl()}/modules/${this.get('id')}`
      }
    }

    this.prototype.toJSONs = {
      generic() {
        return {module_item: {published: this.get('published')}}
      },
      module() {
        return {module: {published: this.get('published')}}
      }
    }

    this.prototype.disabledMessages = {
      generic() {
        if (this.get('module_item_name')) {
          return I18n.t('Publishing %{item_name} is disabled', {
            item_name: this.get('module_item_name')
          })
        } else {
          return I18n.t('Publishing is disabled for this item')
        }
      },

      assignment() {
        if (this.get('module_item_name')) {
          return I18n.t("Can't unpublish %{item_name} if there are student submissions", {
            item_name: this.get('module_item_name')
          })
        } else {
          return I18n.t("Can't unpublish if there are student submissions")
        }
      },

      quiz() {
        if (this.get('module_item_name')) {
          return I18n.t("Can't unpublish %{item_name} if there are student submissions", {
            item_name: this.get('module_item_name')
          })
        } else {
          return I18n.t("Can't unpublish if there are student submissions")
        }
      },
      discussion_topic() {
        if (this.get('module_item_name')) {
          return I18n.t("Can't unpublish %{item_name} if there are student submissions", {
            item_name: this.get('module_item_name')
          })
        } else {
          return I18n.t("Can't unpublish if there are student submissions")
        }
      }
    }
  }

  branch(key) {
    return (this[key][this.get('module_type')] || this[key].generic).call(this)
  }

  url() {
    return this.branch('urls')
  }
  toJSON() {
    return this.branch('toJSONs')
  }
  disabledMessage() {
    return this.branch('disabledMessages')
  }

  baseUrl() {
    return `/api/v1/courses/${this.get('course_id')}`
  }

  publish() {
    return this.save('published', true)
  }

  unpublish() {
    return this.save('published', false)
  }
}

PublishableModuleItem.initClass()
