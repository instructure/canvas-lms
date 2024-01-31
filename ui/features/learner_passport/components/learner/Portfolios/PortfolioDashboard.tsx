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
import PortfolioCard, {PORTFOLIO_CARD_WIDTH, PORTFOLIO_CARD_HEIGHT} from './PortfolioCard'
import {showUnimplemented} from '../../shared/utils'
import type {PortfolioData} from '../../types'
import NamingModal from '../../shared/NamingModal'
import {renderCardSkeleton} from '../../shared/CardSkeleton'
import confirm from '../../shared/Confirmation'

const PortfolioDashboard = () => {
  const navigate = useNavigate()
  const submit = useSubmit()
  const portfolios = useLoaderData() as PortfolioData[]
  const [createModalIsOpen, setCreateModalIsOpen] = useState(false)
  const [renameModalIsOpen, setRenameModalIsOpen] = useState(false)
  const [actionPortfolioId, setActionProjectId] = useState('')

  const url = new URL(window.location.href)
  if (url.searchParams.has('dupe')) {
    const title = url.searchParams.get('dupe') || 'Portfolio'
    showFlashAlert({message: `"${title}" duplicated`, type: 'success'})
    window.history.replaceState(window.history.state, '', url.pathname)
  }
  if (url.searchParams.has('delete')) {
    const title = url.searchParams.get('delete') || 'Portfolio'
    showFlashAlert({message: `"${title}" deleted`, type: 'success'})
    window.history.replaceState(window.history.state, '', url.pathname)
  }

  const handleDismissCreateModal = useCallback(() => {
    setCreateModalIsOpen(false)
    setRenameModalIsOpen(false)
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

  const handleRenameProfile = useCallback(
    (f: HTMLFormElement) => {
      setRenameModalIsOpen(false)
      submit(f, {method: 'POST', action: 'rename'})
    },
    [submit]
  )

  const handleCardAction = useCallback(
    async (portfolioId: string, action: string) => {
      switch (action) {
        case 'duplicate':
          {
            const portfolio = portfolios.find(p => p.id === portfolioId)
            if (portfolio) {
              submit(
                {portfolioId, title: portfolio.title},
                {method: 'PUT', action: `duplicate/${portfolioId}`}
              )
            }
          }
          break
        case 'edit':
          navigate(`../edit/${portfolioId}`)
          break
        case 'view':
          navigate(`../view/${portfolioId}`)
          break
        case 'delete':
          {
            const portfolio = portfolios.find(p => p.id === portfolioId)
            if (portfolio) {
              const ok = await confirm(
                <div>
                  <span>Are you sure you want to delete &quot;{portfolio.title}&quot;</span>?
                </div>
              )
              if (ok) {
                submit(
                  {portfolioId, title: portfolio.title},
                  {method: 'PUT', action: `delete/${portfolioId}`}
                )
              }
            }
          }

          break
        case 'rename':
          setActionProjectId(portfolioId)
          setRenameModalIsOpen(true)
          break
        default:
          showUnimplemented({currentTarget: {textContent: action}})
      }
    },
    [navigate, portfolios, submit]
  )

  return (
    <div style={{maxWidth: '1260px', margin: '0 auto'}}>
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
        {portfolios?.length > 0 ? null : (
          <View as="div" margin="0">
            <Text size="medium">No portfolios created</Text>
          </View>
        )}
        <View as="div" margin="small 0">
          {portfolios && portfolios.length > 0 ? (
            <Flex gap="medium" wrap="wrap">
              {portfolios.map(portfolio => (
                <Flex.Item shouldGrow={false} shouldShrink={false} key={portfolio.id}>
                  <View as="div" shadow="resting">
                    <PortfolioCard
                      id={portfolio.id}
                      title={portfolio.title}
                      heroImageUrl={portfolio.heroImageUrl}
                      onAction={handleCardAction}
                    />
                  </View>
                </Flex.Item>
              ))}
            </Flex>
          ) : (
            renderCardSkeleton(PORTFOLIO_CARD_WIDTH, PORTFOLIO_CARD_HEIGHT)
          )}
        </View>
      </View>
      <NamingModal
        objectType="Portfolio"
        objectId={actionPortfolioId}
        mode={createModalIsOpen ? 'create' : 'rename'}
        currentName={
          renameModalIsOpen ? portfolios.find(p => p.id === actionPortfolioId)?.title : undefined
        }
        open={createModalIsOpen || renameModalIsOpen}
        onDismiss={handleDismissCreateModal}
        onSubmit={createModalIsOpen ? handleCreateNewPortfolio : handleRenameProfile}
      />
    </div>
  )
}

export default PortfolioDashboard
