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

export const ButtonBlockPreview = () => (
  <BlockPreviewLayout
    image={<SVGWrapper url="/images/block-content-editor/button-1.svg" />}
    title={I18n.t('Button')}
    description={[
      I18n.t(
        "Use this block to add a clear call-to-action—like 'Start Quiz', 'View Assignment', or 'Visit Website'. You can customise the button text, style, and destination link.",
      ),
      I18n.t('You can customise the button text, style, and destination link.'),
    ]}
    legend={I18n.t(
      'In this block, you can only add buttons. For additional elements you have to add separate blocks.',
    )}
  />
)
