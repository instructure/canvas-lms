/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!not_found_index'
import React from 'react'

import Container from '@instructure/ui-core/lib/components/Container'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'

import SVGWrapper from '../shared/SVGWrapper'

const NotFoundArtwork = () => (
  <div className="not_found_page_artwork">
    <Container margin="large auto" textAlign="center" display="block">
      <Container margin="large auto" size="small" display="block">
        <SVGWrapper url="/images/not_found_page/empty-planet.svg" />
      </Container>
      <Heading level="h2" as="h1" margin="x-small 0 0">
        {I18n.t('Whoops... Looks like nothing is here!')}
      </Heading>
      <Container margin="small" display="block">
        <Text level="h4" margin="x-small">
          {I18n.t("We couldn't find that page!")}
        </Text>
      </Container>
    </Container>
  </div>
)

export default NotFoundArtwork
