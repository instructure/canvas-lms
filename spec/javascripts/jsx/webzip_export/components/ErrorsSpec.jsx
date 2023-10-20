/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import enzyme from 'enzyme'
import Errors from 'ui/features/webzip_export/react/components/Errors'

QUnit.module('Web Zip Export Errors')

test('renders the Error component', () => {
  const errors = [{response: 'Instance of demon found in code', code: 666}]
  const tree = enzyme.shallow(<Errors errors={errors} />)
  const node = tree.find('.webzipexport__errors')
  ok(node.exists())
})
