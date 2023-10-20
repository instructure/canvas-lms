/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import CanvasModal from '@canvas/instui-bindings/react/Modal'
import classSet from '@canvas/quiz-legacy-client-apps/util/class_set'
import formatNumber from '../../../util/format_number'
import Help from './help'
import {useScope as useI18nScope} from '@canvas/i18n'
import K from '../../../constants'
import React, {useState} from 'react'
import ScreenReaderContent from '@canvas/quiz-legacy-client-apps/react/components/screen_reader_content'
import SightedUserContent from '@canvas/quiz-legacy-client-apps/react/components/sighted_user_content'
import {IconQuestionLine} from '@instructure/ui-icons'

const I18n = useI18nScope('quiz_statistics.discrimination_index')

const DiscriminationIndex = ({discriminationIndex: di = 0}) => {
  const [displayingHelp, displayHelp] = useState(false)
  const passing = di > K.DISCRIMINATION_INDEX_THRESHOLD ? '+' : '-'
  const sign = di == 0 ? '' : di > 0 ? '+' : '-' // "", "-", or "+"
  const className = {
    index: true,
    positive: passing === '+',
    negative: passing !== '+',
  }

  return (
    <section className="discrimination-index-section">
      <div>
        <SightedUserContent>
          <em className={classSet(className)}>
            <span className="sign">{sign}</span>
            {formatNumber(Math.abs(di))}
          </em>

          <p>
            {I18n.t('discrimination_index', 'Discrimination Index')}

            <button
              type="button"
              data-testid="display-help"
              className="Button Button--icon-action help-trigger"
              title={I18n.t(
                'discrimination_index_dialog_trigger',
                'Learn more about the Discrimination Index.'
              )}
              tabIndex="0"
              onClick={() => displayHelp(true)}
            >
              <IconQuestionLine />
            </button>

            <CanvasModal
              open={displayingHelp}
              onDismiss={() => displayHelp(false)}
              label={I18n.t('discrimination_index_dialog_title', 'The Discrimination Index Chart')}
            >
              <Help style={{width: 480}} />
            </CanvasModal>
          </p>
        </SightedUserContent>

        <ScreenReaderContent>
          {I18n.t('audible_discrimination_index', 'Discrimination Index: %{number}.', {
            number: formatNumber(di),
          })}
        </ScreenReaderContent>
      </div>
    </section>
  )
}

export default DiscriminationIndex
