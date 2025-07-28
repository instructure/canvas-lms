/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import React from 'react'
import PropTypes from 'prop-types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type ErrorBoundaryState = {
  hasError: boolean
}

type ErrorBoundaryProps = {
  children: React.ReactNode[]
}

class ErrorBoundary extends React.Component {
  static propTypes = {
    children: PropTypes.node,
  }

  state: ErrorBoundaryState

  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = {hasError: false}
  }

  static getDerivedStateFromError(_error: Error) {
    // Update state so the next render will show the fallback UI.
    return {
      hasError: true,
    }
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error(error, '\n', info.componentStack)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{margin: '1rem'}}>
          <h2>{I18n.t('Something went wrong.')}</h2>
        </div>
      )
    }
    // @ts-expect-error
    return this.props.children
  }
}

export {ErrorBoundary}
