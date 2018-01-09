//
// Copyright (C) 2012 - present Instructure, Inc.
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

// copied from: https://gist.github.com/1998897

import Backbone from 'node_modules-version-of-backbone'
import _ from 'underscore'
import $ from 'jquery'
import authenticity_token from '../behaviors/authenticity_token'
import htmlEscape from 'str/htmlEscape'
/*
xsslint safeString.identifier iframeId httpMethod
xsslint jqueryObject.identifier el
*/

Backbone.syncWithoutMultipart = Backbone.sync
Backbone.syncWithMultipart = function (method, model, options) {
  // Create a hidden iframe
  const iframeId = _.uniqueId('file_upload_iframe_')
  const $iframe = $(`<iframe id="${iframeId}" name="${iframeId}"></iframe>`).hide()
  const dfd = new $.Deferred()

  // Create a hidden form
  const httpMethod = {
    create: 'POST',
    update: 'PUT',
    delete: 'DELETE',
    read: 'GET',
  }[method]

  function toForm (object, nested, asArray) {
    const inputs = _.map(object, (attr, key) => {
      if (nested) key = `${nested}[${asArray ? '' : key}]`

      if (_.isElement(attr)) {
        // leave a copy in the original form, since we're moving it
        const $orig = $(attr)
        $orig.after($orig.clone(true))
        return attr
      } else if (!_.isEmpty(attr) && (_.isArray(attr) || typeof attr === 'object')) {
        return toForm(attr, key, _.isArray(attr))
      } else if (!`${key}`.match(/^_/) && attr != null && attr instanceof Date) {
        return $('<input/>', {
          name: key,
          value: attr.toISOString(),
        })[0]
      } else if (!`${key}`.match(/^_/) && attr != null && typeof attr !== 'object' && typeof attr !== 'function') {
        return $('<input/>', {
          name: key,
          value: attr,
        })[0]
      }
    })
    return _.flatten(inputs)
  }

  const $form = $(
    `<form
      enctype='multipart/form-data'
      target='${iframeId}'
      action='${htmlEscape(options.url || model.url())}'
      method='POST'
    >
    </form>`
  ).hide()

  // pass proxyAttachment if the upload is being proxied through canvas (deprecated)
  if (options.proxyAttachment) {
    $form.prepend(
      `<input type='hidden' name='_method' value='${httpMethod}' />
      <input type='hidden' name='authenticity_token' value='${htmlEscape(authenticity_token())}' />`
    )
  }

  _.each(toForm(model.toJSON()), (el) => {
    if (!el) return
    // s3 expects the file param last
    $form[el.name === 'file' ? 'append' : 'prepend'](el)
  })

  $(document.body).prepend($iframe, $form)

  function callback () {
    const iframeBody = $iframe[0].contentDocument &&
                       $iframe[0].contentDocument.body

    let response = $.parseJSON($(iframeBody).text())
    // in case the form redirects after receiving the upload (API uploads),
    // prevent trying to work with an empty response
    if (!response) return

    // TODO: Migrate to api v2. Make this check redundant
    response = response.objects != null ? response.objects : response

    if (iframeBody.className === 'error') {
      if (typeof options.error === 'function') options.error(response)
      dfd.reject(response)
    } else {
      if (typeof options.success === 'function') options.success(response)
      dfd.resolve(response)
    }

    $iframe.remove()
    $form.remove()
  }

  // non-IE
  $iframe[0].onload = callback

  $form[0].submit()
  return dfd
}

export default (Backbone.sync = function (method, model, options) {
  return Backbone[options && options.multipart ? 'syncWithMultipart' : 'syncWithoutMultipart'].apply(this, arguments)
})
