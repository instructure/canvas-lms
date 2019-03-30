/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import 'jest-dom/extend-expect'
import 'react-testing-library/cleanup-after-each'

// Because the RCE tries to pull in coffeescript files through jquery. Once it
// doesn't, we could remove this, though it might make sense to leave it if
// rendering the actual rce is slow.
jest.mock('jsx/shared/rce/RichContentEditor')
