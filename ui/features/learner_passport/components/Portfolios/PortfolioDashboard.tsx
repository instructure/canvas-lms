/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {useSubmit, useLoaderData, useNavigate} from 'react-router-dom'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconPlusLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import PortfolioCard, {PortfolioCardSkeleton} from './PortfolioCard'
import type {PortfolioData} from '../types'
import CreatePortfolioModal from './CreatePortfolioModal'

function renderSkeleton() {
  return (
    <Flex gap="medium" wrap="wrap">
      {['a', 'b', 'c'].map(key => (
        <Flex.Item shouldGrow={false} shouldShrink={false} key={key}>
          <PortfolioCardSkeleton />
        </Flex.Item>
      ))}
    </Flex>
  )
}

const PortfolioDashboard = () => {
  const navigate = useNavigate()
  const submit = useSubmit()
  const portfolios = useLoaderData() as PortfolioData[]
  const [createModalIsOpen, setCreateModalIsOpen] = useState(false)

  const handleDismissCreateModal = useCallback(() => {
    setCreateModalIsOpen(false)
  }, [])

  const handleCreateClick = useCallback(() => {
    setCreateModalIsOpen(true)
  }, [])

  const handleCreateNewPortfolio = useCallback(
    (f: HTMLFormElement) => {
      setCreateModalIsOpen(false)
      submit(f, {method: 'PUT'})
    },
    [submit]
  )

  const handleCardAction = useCallback(
    (portfolioId: string, action: string) => {
      switch (action) {
        case 'duplicate':
          navigate(`duplicate/${portfolioId}`)
          break
        case 'edit':
          navigate(`../edit/${portfolioId}`)
          break
        case 'view':
          navigate(`../view/${portfolioId}`)
          break
        default:
          showFlashAlert({
            message: `portfolio ${portfolioId} action ${action}`,
            type: 'success',
          })
      }
    },
    [navigate]
  )

  return (
    <>
      <Flex justifyItems="space-between">
        <Flex.Item shouldGrow={true}>
          <Heading level="h1" themeOverride={{h1FontWeight: 700}}>
            Portfolios
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <Button renderIcon={IconPlusLine} color="primary" onClick={handleCreateClick}>
            Create Portfolio
          </Button>
        </Flex.Item>
      </Flex>
      <View as="div" margin="small 0 large 0">
        <Text size="large">
          Create and share a portfolio of your achievements, work, eduation history, and work
          experience.
        </Text>
      </View>
      <View>
        {portfolios?.length > 0 || (
          <View as="div" margin="0">
            <Text size="x-small">No portfolios created</Text>
          </View>
        )}
        <View as="div" margin="small 0">
          {portfolios && portfolios.length > 0 ? (
            <Flex gap="medium" wrap="wrap">
              {portfolios.map(portfolio => (
                <Flex.Item shouldGrow={false} shouldShrink={false} key={portfolio.id}>
                  <PortfolioCard
                    id={portfolio.id}
                    title={portfolio.title}
                    heroImageUrl={portfolio.heroImageUrl}
                    onAction={handleCardAction}
                  />
                </Flex.Item>
              ))}
            </Flex>
          ) : (
            renderSkeleton()
          )}
        </View>
      </View>
      <CreatePortfolioModal
        open={createModalIsOpen}
        onDismiss={handleDismissCreateModal}
        onSubmit={handleCreateNewPortfolio}
      />
    </>
  )
}

export default PortfolioDashboard
