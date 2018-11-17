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

export default class RedirectReturnContainer {
  constructor() {
    this._contentReady = this._contentReady.bind(this)
    this._contentCancel = this._contentCancel.bind(this)
    this.redirectToSuccessUrl = this.redirectToSuccessUrl.bind(this)
    this.createMigration = this.createMigration.bind(this)
  }

  attachLtiEvents() {
    $(window).on('externalContentReady', this._contentReady)
    $(window).on('externalContentCancel', this._contentCancel)
  }

  _contentReady(event, data) {
    if (data && data.return_type === 'file') {
      return this.createMigration(data.url)
    } else {
      return this.redirectToSuccessUrl()
    }
  }

  _contentCancel(event, data) {
    location.href = this.cancelUrl
  }

  redirectToSuccessUrl() {
    location.href = this.successUrl
  }

  createMigration(file_url) {
    const data = {
      migration_type: 'canvas_cartridge_importer',
      settings: {
        file_url
      }
    }

    const migrationUrl = `/api/v1/courses/${ENV.course_id}/content_migrations`
    return $.ajaxJSON(migrationUrl, 'POST', data, this.redirectToSuccessUrl, this.handleError)
  }

  handleError(data) {
    return $.flashError(data.message)
  }
}
RedirectReturnContainer.prototype.successUrl = ENV.redirect_return_success_url
RedirectReturnContainer.prototype.cancelUrl = ENV.redirect_return_cancel_url
