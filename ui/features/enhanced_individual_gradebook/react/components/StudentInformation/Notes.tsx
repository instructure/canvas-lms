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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  currentStudentNotes: string
  disabled: boolean
  handleSubmitNotes: (notes: string) => void
}

export default function Notes({currentStudentNotes, disabled, handleSubmitNotes}: Props) {
  const [notes, setNotes] = useState(currentStudentNotes)
  const {Row: GridRow, Col: GridCol} = Grid as any
  useEffect(() => {
    setNotes(currentStudentNotes)
  }, [currentStudentNotes])

  return (
    <>
      <View as="h4">{I18n.t('Notes')}</View>
      <Grid>
        <GridRow>
          <GridCol width={{small: 12, medium: 12, large: 8, xLarge: 8}}>
            <TextArea
              resize="vertical"
              data-testid="notes-text-box"
              onBlur={() => handleSubmitNotes(notes)}
              label=""
              value={notes}
              onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setNotes(e.target.value)}
              disabled={disabled}
            />
          </GridCol>
        </GridRow>
      </Grid>
    </>
  )
}
