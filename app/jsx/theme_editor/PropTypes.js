/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import _ from 'underscore'

  const MD5_REGEX = /[0-9a-fA-F]{32}$/
  const types = {}

  types.md5 = (props, propName, componentName) => {
    var val = props[propName];
    if (val !== null && !MD5_REGEX.test(val)) {
      return new Error(`Invalid md5: ${val} propName: ${propName} componentName: ${componentName}`)
    }
  }

  const baseVarDef = {
    default: PropTypes.string.isRequired,
    human_name: PropTypes.string.isRequired,
    variable_name: PropTypes.string.isRequired,
  }

  types.variables = PropTypes.objectOf(PropTypes.string).isRequired

  types.color = PropTypes.shape(_.extend({
    type: PropTypes.oneOf(['color']).isRequired
  }, baseVarDef))

  types.image = PropTypes.shape(_.extend({
    type: PropTypes.oneOf(['image']).isRequired,
    accept: PropTypes.string.isRequired,
    helper_text: PropTypes.string
  }, baseVarDef))

  types.percentage = PropTypes.shape(_.extend({
    type: PropTypes.oneOf(['percentage']).isRequired,
    helper_text: PropTypes.string
  },baseVarDef))

  types.varDef = PropTypes.oneOfType([types.image, types.color, types.percentage])

  types.brandConfig = PropTypes.shape({
    md5: types.md5,
    variables: types.variables
  })

  types.sharedBrandConfig = PropTypes.shape({
    account_id: PropTypes.string,
    brand_config: types.brandConfig.isRequired,
    name: PropTypes.string.isRequired
  })

  types.variableGroup = PropTypes.shape({
    group_name: PropTypes.string.isRequired,
    variables: PropTypes.arrayOf(types.varDef).isRequired
  })

  types.userVariableInput = PropTypes.shape({
    val: PropTypes.string,
    invalid: PropTypes.bool
  })

  types.variableSchema = PropTypes.arrayOf(types.variableGroup).isRequired

  types.variableDescription = PropTypes.shape({
    default: PropTypes.string.isRequired,
    type: PropTypes.oneOf(['color', 'image', 'percentage']).isRequired,
    variable_name: PropTypes.string.isRequired
  })

  types.brandableVariableDefaults = PropTypes.objectOf(types.variableDescription)

export default types
