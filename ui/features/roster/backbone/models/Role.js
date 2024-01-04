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

import {Model} from '@canvas/backbone'
import {isEmpty} from 'lodash'

export default class Role extends Model {
  initialize() {
    return super.initialize(...arguments)
  }

  isNew() {
    return this.get('id') == null
  }

  // Method Summary
  //   urlRoot is used in url to generate the a restful url
  //
  // @api override backbone
  urlRoot() {
    return `/api/v1/accounts/${ENV.ACCOUNT_ID}/roles`
  }

  // Method Summary
  //   See backbones explaination of a validate method for in depth
  //   details but in short, if your return something from validate
  //   there is an error, if you don't, there are no errors. Throw
  //   in the error object to any validation function you make. It's
  //   passed by reference dawg.
  // @api override backbone
  validate(_attrs) {
    const errors = {}
    if (!isEmpty(errors)) return errors
  }

  editable() {
    return this.get('workflow_state') !== 'built_in'
  }
}

// Method Summary
//   ResourceName is used by a collection to help determin the url
//   that should be generated for the resource.
// @api custom backbone override
Role.prototype.resourceName = 'roles'
