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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

import SVGWrapper from '@canvas/svg-wrapper'

const I18n = useI18nScope('not_found_index')

const NotFoundArtwork = () => (
  <div className="not_found_page_artwork">
    <View margin="large auto" textAlign="center" display="block">
      {/* maxWidth="small" is being ignored in instui v6.27 */}
      <View margin="large auto" maxWidth="30rem" display="block">
        <SVGWrapper url="/images/not_found_page/empty-planet.svg" />
      </View>
      <Heading level="h2" as="h1" margin="x-small 0 0">
        {I18n.t('Whoops... Looks like nothing is here!')}
      </Heading>
      <View margin="small" display="block">
        <Text level="h4" margin="x-small">
          {I18n.t("We couldn't find that page!")}
        </Text>
      </View>
    </View>
  </div>
)

export default NotFoundArtwork
