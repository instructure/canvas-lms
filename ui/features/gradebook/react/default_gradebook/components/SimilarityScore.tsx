// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React, {PureComponent} from 'react'
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'

import SimilarityIcon from './SimilarityIcon'

import {useScope as useI18nScope} from '@canvas/i18n'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('gradebook')

type Props = {
  hasAdditionalData?: boolean
  reportUrl?: string
  similarityScore?: number
  status: string
}

export default class SimilarityScore extends PureComponent<Props> {
  render() {
    const {hasAdditionalData, reportUrl, similarityScore, status} = this.props

    let statusMessage
    if (status === 'error') {
      statusMessage = I18n.t(
        'Error submitting to plagiarism service. You may resubmit from SpeedGrader.'
      )
    } else if (status === 'pending') {
      statusMessage = I18n.t('Submission is being processed by plagiarism service.')
    }
    const statusIcon = <SimilarityIcon similarityScore={similarityScore} status={status} />

    const displayScore = I18n.n(similarityScore, {precision: 1})
    return (
      <Grid rowSpacing="none">
        {statusMessage ? (
          <Grid.Row>
            <Grid.Col width="auto">{statusIcon}</Grid.Col>
            <Grid.Col>{statusMessage}</Grid.Col>
          </Grid.Row>
        ) : (
          <Grid.Row>
            <Grid.Col>
              <Link
                renderIcon={statusIcon}
                href={reportUrl}
                isWithinText={false}
                theme={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
              >
                <Text margin="auto auto auto small">
                  {I18n.t('%{score}% similarity score', {score: displayScore})}
                </Text>
              </Link>
            </Grid.Col>
          </Grid.Row>
        )}

        {hasAdditionalData && (
          <Grid.Row>
            <Grid.Col>
              <Text as="p" size="x-small" lineHeight="condensed" margin="small auto auto auto">
                {I18n.t(
                  'This submission has plagiarism data for multiple attachments. To see all reports, open SpeedGrader.'
                )}
              </Text>
            </Grid.Col>
          </Grid.Row>
        )}
      </Grid>
    )
  }
}
