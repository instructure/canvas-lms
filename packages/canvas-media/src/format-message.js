/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import formatMessage from 'format-message'
import generateId from 'format-message-generate-id/underscored_crc32'

const ns = formatMessage.namespace()

ns.addLocale = translations => {
  const locale = Object.keys(translations)[0]
  ns.setup({
    translations: {...ns.setup().translations, ...translations},
    locale,
    generateId,
    missingTranslation: 'ignore',
  })
}

export default ns
