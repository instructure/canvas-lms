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

import {ApolloProvider, createClient} from '@canvas/apollo'
import GradebookMenu from '@canvas/gradebook-menu'
import LoadingIndicator from '@canvas/loading-indicator'
import EnhancedIndividualGradebook from './EnhancedIndividualGradebook'

export default function EnhancedIndividualGradebookWrapper() {
  const [client, setClient] = useState<any>(null) // TODO: remove <any>
  const [loading, setLoading] = useState(true)

  if (!ENV.GRADEBOOK_OPTIONS) {
    throw new Error('ENV.GRADEBOOK_OPTIONS is not defined')
  }

  useEffect(() => {
    const setupApolloClient = async () => {
      // TODO: Properly set up cache
      // const cache = await createPersistentCache([cache_key])
      // setClient(createClient({cache}))
      setClient(createClient())
      setLoading(false)
    }
    setupApolloClient()
  }, [])

  if (loading) {
    return <LoadingIndicator />
  }

  return (
    <>
      <GradebookMenu
        courseUrl={ENV.GRADEBOOK_OPTIONS.context_url}
        learningMasteryEnabled={Boolean(ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled)}
        enhancedIndividualGradebookEnabled={Boolean(
          ENV.GRADEBOOK_OPTIONS.individual_gradebook_enhancements
        )}
        variant="EnhancedIndividualGradebook"
      />
      <ApolloProvider client={client}>
        <EnhancedIndividualGradebook />
      </ApolloProvider>
    </>
  )
}
