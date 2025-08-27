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

export const HighlightBlockPreview = () => (
  <BlockPreviewLayout
    image={<SVGWrapper url="/images/block-content-editor/page-highlight-no-icon.svg" />}
    title={I18n.t('Page highlight')}
    description={[
      I18n.t(
        'Use this block to draw attention to key information—like deadlines, reminders, or important updates.',
      ),
      I18n.t(
        'Includes simple styling options (like background color or icon) to help the message stand out.',
      ),
    ]}
    legend={I18n.t(
      'Keep the content brief. For more complex layouts (e.g. lists, media, or detailed text), use additional blocks.',
    )}
  />
)
