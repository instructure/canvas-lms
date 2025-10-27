/* eslint-disable react/prop-types */
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

import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('CommentLibrary')

type SuggestionsEnabledToggleSectionProps = {
  checked: boolean
  onChange: (checked: boolean) => void
}
export const SuggestionsEnabledToggleSection: React.FC<SuggestionsEnabledToggleSectionProps> = ({
  checked,
  onChange,
}) => {
  const handleChange = async (checked: boolean) => {
    onChange(checked)

    // using pure api calls here, v2 does not have react-query set up
    try {
      await doFetchApi({
        path: '/api/v1/users/self/settings',
        method: 'PUT',
        body: {comment_library_suggestions_enabled: checked},
      })
    } catch {
      showFlashAlert({
        message: I18n.t('Error saving suggestion preference'),
        type: 'error',
      })
    }
  }

  return (
    <View textAlign="start" as="div" padding="0 0 medium small" borderWidth="none none medium none">
      <PresentationContent>
        <View as="div" display="inline-block">
          <Text size="small" weight="bold" data-testid="suggestions-toggle-label">
            {I18n.t('Show suggestions when typing')}
          </Text>
        </View>
      </PresentationContent>
      <div
        style={{display: 'inline-block', float: 'right'}}
        data-testid="comment-suggestions-when-typing"
      >
        <Checkbox
          label={
            <ScreenReaderContent>{I18n.t('Show suggestions when typing')}</ScreenReaderContent>
          }
          variant="toggle"
          data-testid="suggestions-when-typing-toggle"
          size="small"
          inline={true}
          onChange={e => handleChange(e.target.checked)}
          checked={checked}
        />
      </div>
    </View>
  )
}
