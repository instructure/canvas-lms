/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {BlockPreviewLayout} from './BlockPreviewLayout'
import SVGWrapper from '@canvas/svg-wrapper'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('page_editor')

export const SeparatorLineBlockPreview = () => (
  <BlockPreviewLayout
    image={<SVGWrapper url="/images/block-content-editor/separator-line-thin.svg" />}
    title={I18n.t('Separation line')}
    description={[I18n.t('Add a horizontal line to visually separate content.')]}
    legend={I18n.t(
      'For more complex elements like images, tables, or videos, please use the dedicated blocks.',
    )}
  />
)
