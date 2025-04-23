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
import React from 'react'
import {Text} from '@instructure/ui-text'
import EmptyDesert from '@canvas/images/react/EmptyDesert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {IconAiLine,IconRefreshLine} from '@instructure/ui-icons'
import LoadingIndicator from '@canvas/loading-indicator/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

import noDiscussion from '../../../images/no-discussion.svg'

const I18n = createI18nScope('discussion_insights')

type PlaceholderProps = {
  type: 'error' | 'loading' | 'no-reply' | 'no-results' | 'no-data'
  errorType?: 'generating' | 'loading'
  onClick?: () => void
}

type ErrorProps = Required<Omit<PlaceholderProps, 'type'>>

const Template = ({
  imageElement,
  title,
  description,
  buttonText,
  onClick,
  Icon,
}: {
  imageElement: React.ReactNode | JSX.Element
  title: string
  description?: string
  buttonText?: string
  onClick?: () => void
  Icon?: JSX.Element
}) => (
  <>
    <View as="div" margin="0 0 medium 0">
      {imageElement}
    </View>
    <View>
      <View as="div" margin="0 0 x-small 0">
        <Text size="large">{title}</Text>
      </View>
      {description && (
        <View as="div" margin="0 0 large 0">
          <Text>{description}</Text>
        </View>
      )}
    </View>
    {buttonText && (
      <View as="div">
        <Link data-testid="placeholder-action-button" onClick={onClick} renderIcon={Icon || IconAiLine}>
          {buttonText}
        </Link>
      </View>
    )}
  </>
)

const Error = ({errorType, onClick}: ErrorProps) => (
  <Template
    imageElement={
      <View as="div" maxWidth="282px" margin="auto">
        <img alt="Error ship" src={errorShipUrl} />
      </View>
    }
    title={
      errorType === 'generating'
        ? I18n.t('There was an error generating the insights')
        : I18n.t('There was an error loading the insights')
    }
    description={I18n.t('Please try again')}
    buttonText={errorType === 'generating' ? I18n.t('Generate Insights') : I18n.t('Reload results')}
    onClick={onClick}
    Icon={errorType === 'generating' ? <IconRefreshLine /> : <IconAiLine />}
  />
)

const NoData = ({onClick}: {onClick: () => void}) => (
  <Template
    imageElement={
      <View as="div" margin="auto">
        <EmptyDesert />
      </View>
    }
    title={I18n.t('You haven’t generated any insights yet')}
    description={I18n.t('Try adding a specific prompt or just generate without one')}
    buttonText={I18n.t('Generate Insights')}
    onClick={onClick}
  />
)

const NoReply = () => (
  <Template
    imageElement={
      <View as="div" maxWidth="352px" margin="auto">
        <img alt="No replies" src={noDiscussion} />
      </View>
    }
    title={I18n.t('There are no replies for this topic yet')}
    description={I18n.t('Please try again when more replies are available')}
  />
)

const NoResults = () => (
  <Template
    imageElement={
      <View as="div" margin="auto">
        <EmptyDesert />
      </View>
    }
    title={I18n.t('No results found')}
  />
)

const Loading = () => <LoadingIndicator />

const Placeholder: React.FC<PlaceholderProps> = ({type, errorType, onClick}) => {
  let content = null

  switch (type) {
    case 'error': {
      content = <Error errorType={errorType!} onClick={onClick!} />
      break
    }
    case 'loading': {
      content = <Loading />
      break
    }
    case 'no-data': {
      content = <NoData onClick={onClick!} />
      break
    }
    case 'no-reply': {
      content = <NoReply />
      break
    }
    case 'no-results': {
      content = <NoResults />
      break
    }
  }

  return <View textAlign="center">{content}</View>
}

export default Placeholder
