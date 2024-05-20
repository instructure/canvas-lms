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
import {useActionData, useLoaderData, useNavigate} from 'react-router-dom'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconDownloadLine,
  IconEditLine,
  IconPrinterLine,
  IconReviewScreenLine,
  IconShareLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import type {PortfolioDetailData} from '../../types'
import {showUnimplemented} from '../../shared/utils'
import PortfolioView from './PortfolioView'
import PortfolioPreviewModal from './PortfolioPreviewModal'

const PortfolioViewPage = () => {
  const navigate = useNavigate()
  const create_portfolio = useActionData() as PortfolioDetailData
  const edit_portfolio = useLoaderData() as PortfolioDetailData
  const portfolio = create_portfolio || edit_portfolio
  const [showPreview, setShowPreview] = useState(false)

  const handleEditClick = useCallback(() => {
    navigate(`../edit/${portfolio.id}`)
  }, [navigate, portfolio.id])

  const handlePreviewClick = useCallback(() => {
    setShowPreview(true)
  }, [])

  const handleClosePreview = useCallback(() => {
    setShowPreview(false)
  }, [])

  return (
    <View as="div" id="portfolio_view_page" maxWidth="986px" margin="0 auto">
      <Breadcrumb label="You are here:" size="small">
        <Breadcrumb.Link
          href={`/users/${ENV.current_user.id}/passport/learner/portfolios/dashboard`}
        >
          Portfolios
        </Breadcrumb.Link>
        <Breadcrumb.Link>{portfolio.title}</Breadcrumb.Link>
      </Breadcrumb>
      <Flex as="div" margin="medium 0 medium 0">
        <Flex.Item shouldGrow={true}>
          <Heading level="h1" themeOverride={{h1FontWeight: 700}}>
            {portfolio.title}
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <Button margin="0 x-small 0 0" renderIcon={IconEditLine} onClick={handleEditClick}>
            Edit
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconDownloadLine} onClick={showUnimplemented}>
            Download
          </Button>
          <Button margin="0 x-small 0 0" renderIcon={IconPrinterLine} onClick={window.print}>
            Print
          </Button>
          <Button
            margin="0 x-small 0 0"
            renderIcon={IconReviewScreenLine}
            onClick={handlePreviewClick}
          >
            Preview
          </Button>
          <Button color="primary" margin="0" renderIcon={IconShareLine} onClick={showUnimplemented}>
            Share
          </Button>
        </Flex.Item>
      </Flex>
      <View as="div" shadow="above" margin="0 0 x-large 0">
        <PortfolioView portfolio={portfolio} />
      </View>
      <PortfolioPreviewModal
        portfolio={portfolio}
        open={showPreview}
        onClose={handleClosePreview}
      />
    </View>
  )
}

export default PortfolioViewPage
