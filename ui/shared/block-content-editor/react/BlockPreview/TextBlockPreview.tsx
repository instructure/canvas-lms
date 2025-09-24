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

export const TextBlockPreview = () => (
  <BlockPreviewLayout
    image={<SVGWrapper ariaHidden={true} url="/images/block-content-editor/text-column-1.svg" />}
    title={I18n.t('Text column')}
    description={[
      I18n.t(
        'A basic text block for adding and formatting content like paragraphs, headings, or short notes.',
      ),
      I18n.t(
        'Use multiple columns to place content side by side—perfect for structuring text in two columns, like comparisons, short lists, or paired headings and paragraphs.',
      ),
    ]}
    legend={I18n.t(
      'For more complex elements like images, tables, or videos, please use the dedicated blocks.',
    )}
  />
)
