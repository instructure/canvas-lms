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

import PropTypes from 'prop-types'
import {ApolloProvider, createClient} from '@canvas/apollo'
import MentionDropdown from './MentionDropdown'
import React from 'react'
import GenericErrorPage from '@canvas/generic-error-page'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import AlertManager from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('mentions')

const client = createClient()

const MentionsUI = ({rceRef, onFocusedUserChange, onExited, onSelect, editor}) => {
  return (
    <ApolloProvider client={client}>
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage imageUrl={errorShipUrl} errorCategory={I18n.t('Mentions Error Page')} />
        }
      >
        <AlertManager>
          <MentionDropdown
            rceRef={rceRef}
            onFocusedUserChange={onFocusedUserChange}
            onExited={onExited}
            onSelect={onSelect}
            editor={editor}
          />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>
  )
}

export default MentionsUI

MentionsUI.propTypes = {
  rceRef: PropTypes.object,
  onFocusedUserChange: PropTypes.func,
  onExited: PropTypes.func,
  onSelect: PropTypes.func,
  editor: PropTypes.object,
}

MentionsUI.defaultProps = {
  onFocusedUserChange: () => {},
  onExited: () => {},
  onSelect: () => {},
}
