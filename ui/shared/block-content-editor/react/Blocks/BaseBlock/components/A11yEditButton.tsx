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

import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

type A11yEditButtonProps = {
  onUserAction: () => void
  elementRef?: (element: Element | null) => void
  title: string
}

export const A11yEditButton = ({onUserAction, elementRef, title}: A11yEditButtonProps) => {
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      onUserAction()
    }
  }

  return (
    <Button
      data-focus-reveal-button
      data-testid="a11y-edit-button"
      color="primary"
      aria-label={I18n.t('Edit content for %{title}', {title})}
      onKeyDown={handleKeyDown}
      onClick={onUserAction}
      elementRef={elementRef}
    >
      {I18n.t('Edit')}
    </Button>
  )
}
