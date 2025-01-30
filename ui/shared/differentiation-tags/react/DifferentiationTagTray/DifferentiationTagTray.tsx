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
import pandasBalloonUrl from '../images/pandasBalloon.svg'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('differentiation_tags')

export interface DifferentiationTagTrayProps {
  isOpen: boolean
  onClose: () => void
  differentiationTagCategories: {id: number; name: string}[] | []
  isLoading: boolean
  error: Error | null
}

const Header = ({onClose}: {onClose: () => void}) => (
  <Flex justifyItems="space-between" width="100%" padding="medium">
    <Flex.Item>
      <Heading level="h2" data-testid="differentiation-tag-header">
        {I18n.t('Manage Tags')}
      </Heading>
    </Flex.Item>
    <Flex.Item>
      <CloseButton
        size="medium"
        onClick={onClose}
        screenReaderLabel={I18n.t('Close Differentiation Tag Tray')}
      />
    </Flex.Item>
  </Flex>
)

const DifferentiationTagCategories = ({
  differentiationTagCategories,
}: {differentiationTagCategories: Array<{id: number; name: string}>}) => (
  <List data-testid="differentiation-tag-categories-list">
    {differentiationTagCategories.map(category => (
      <List.Item key={category.id}>
        <Text>{category.name}</Text>
      </List.Item>
    ))}
  </List>
)

const EmptyState = ({onClose}: {onClose: () => void}) => (
  <Flex
    direction="column"
    alignItems="center"
    justifyItems="center"
    padding="medium"
    textAlign="center"
    margin="large 0 0 0"
  >
    <img
      src={pandasBalloonUrl}
      alt="Pandas Balloon"
      style={{width: '160px', height: 'auto', marginBottom: '1rem'}}
    />
    <Heading level="h3" margin="0 0 medium 0">
      {I18n.t('Differentiation Tags')}
    </Heading>
    <Text size="small">{I18n.t('Like groups, but different!')}</Text>
    <Text as="p" size="small">
      {I18n.t(
        'Tags are not visible to students and can be utilized to assign differentiated work and deadlines to students.',
      )}
    </Text>
    <Text size="small">
      <Link href="#" isWithinText={false}>
        {I18n.t('Learn more about how we used your input to create differentiation tags.')}
      </Link>
    </Text>
    <Button onClick={onClose} margin="large 0 0 0" color="primary" size="medium">
      {I18n.t('Get Started')}
    </Button>
  </Flex>
)

export default function DifferentiationTagTray({
  isOpen,
  onClose,
  differentiationTagCategories,
  isLoading,
  error,
}: DifferentiationTagTrayProps) {
  return (
    <View id="manage-differentiation-tag-container" width="100%" display="block">
      <Tray
        onClose={onClose}
        label={I18n.t('Manage Tags')}
        open={isOpen}
        placement="end"
        size="small"
      >
        <Flex direction="column" height="100vh" width="100%">
          <Header onClose={onClose} />
          {isLoading ? (
            <Flex.Item shouldGrow shouldShrink margin="medium">
              <Spinner renderTitle={I18n.t('Loading...')} size="small" />
            </Flex.Item>
          ) : error ? (
            <Flex.Item shouldGrow shouldShrink margin="medium">
              <Text color="danger">
                {I18n.t('Error loading tag differentiation tag categories:')} {error.message}
              </Text>
            </Flex.Item>
          ) : differentiationTagCategories.length === 0 ? (
            <EmptyState onClose={onClose} />
          ) : (
            <Flex.Item shouldGrow shouldShrink margin="medium">
              <DifferentiationTagCategories
                differentiationTagCategories={differentiationTagCategories}
              />
            </Flex.Item>
          )}
        </Flex>
      </Tray>
    </View>
  )
}
