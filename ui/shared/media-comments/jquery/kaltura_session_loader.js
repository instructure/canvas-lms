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

/*
 * Loads kaltura session data, generates options based on session
 */
export default class KalturaSessionLoader {
  loadSession = (url, success, failure) => {
    $.ajaxJSON(url, 'POST', {}, data => {
      if (data.ks) {
        data.ui_conf_id = INST.kalturaSettings.upload_ui_conf
        this.kalturaSession = data
        return success.call()
      } else {
        return failure.call()
      }
    })
    return true
  }

  generateUploadOptions(allowedMedia) {
    return {
      kaltura_session: this.kalturaSession,
      allowedMediaTypes: allowedMedia,
      uploadUrl: this.kalturaUrl('/index.php/partnerservices2/upload'),
      entryUrl: this.kalturaUrl('/index.php/partnerservices2/addEntry'),
      uiconfUrl: this.kalturaUrl('/index.php/partnerservices2/getuiconf'),
      entryDefaults: {
        partnerData: $.mediaComment.partnerData(),
      },
    }
  }

  kalturaUrl(endPoint) {
    return `${this.kalturaProtocol()}//${INST.kalturaSettings.domain}${endPoint}`
  }

  kalturaProtocol() {
    const settingsProtocol = INST?.kalturaSettings?.protocol
    return settingsProtocol ? settingsProtocol + ':' : window.location.protocol
  }
}
