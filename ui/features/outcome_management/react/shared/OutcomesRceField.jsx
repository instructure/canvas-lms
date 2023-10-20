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

import React, {useState, useRef, Suspense} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('OutcomeManagement')

const CanvasRce = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    '@canvas/rce/react/CanvasRce'
  )
)

const OutcomesRceField = ({onChangeHandler, defaultContent}) => {
  const [isLoadingRce, setIsLoadingRce] = useState(true)
  const rceRef = useRef(null)
  const spinner = (
    <View display="block" textAlign="center">
      <Spinner size="large" margin="large auto" renderTitle={() => I18n.t('Loading...')} />
    </View>
  )

  return (
    <>
      <Suspense fallback={null}>
        {/* display: 'none' allows you to load an RCE without
           displaying it which can aleviate load times */}
        <div style={{display: isLoadingRce ? 'none' : ''}}>
          <CanvasRce
            ref={rceRef}
            onInit={() => setIsLoadingRce(false)}
            autosave={false}
            editorOptions={{
              focus: false,
              plugins: [],
            }}
            renderKBShortcutModal={false}
            height={300}
            onContentChange={onChangeHandler}
            defaultContent={defaultContent}
            textareaId="textentry_text"
          />
        </div>
      </Suspense>
      {isLoadingRce && spinner}
    </>
  )
}

OutcomesRceField.propTypes = {
  defaultContent: PropTypes.string,
  onChangeHandler: PropTypes.func.isRequired,
}

OutcomesRceField.defaultProps = {
  defaultContent: '',
}

export default OutcomesRceField
