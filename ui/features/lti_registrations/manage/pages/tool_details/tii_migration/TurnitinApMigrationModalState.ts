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

import {useQuery, useMutation} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import doFetchApi, {doFetchWithSchema} from '@canvas/do-fetch-api-effect'
import * as z from 'zod'

// Zod schemas for type-safe API responses
const ZTiiApMigrationProgress = z.object({
  id: z.string(),
  tag: z.string().nullish(),
  workflow_state: z.enum(['running', 'completed', 'failed', 'queued']),
  completion: z.number().nullish(),
  message: z.string().nullish(),
  results: z
    .object({
      migration_report_url: z.string().nullish(),
      assignment_count: z.number().nullish(),
    })
    .nullish(),
})

export const ZTiiApMigration = z.object({
  account_name: z.string(),
  account_id: z.string(),
  migration_progress: ZTiiApMigrationProgress.nullish(),
})

export type TiiApMigration = z.infer<typeof ZTiiApMigration> & {
  migrateClicked?: boolean
}
export type TiiApMigrationProgress = z.infer<typeof ZTiiApMigrationProgress>

/**
 * Fetches the list of sub-accounts that need Turnitin migration
 * Polls automatically when there are running migrations
 */
export const useTurnitinMigrationData = (rootAccountId: string) => {
  return useQuery({
    queryKey: ['tii_migrations', rootAccountId] as const,
    queryFn: async () => {
      const result = await doFetchWithSchema(
        {
          path: `/api/v1/accounts/${rootAccountId}/asset_processors/tii_migrations`,
        },
        z.array(ZTiiApMigration),
      )
      return result.json
    },
    staleTime: 0,
    refetchInterval: query => {
      const data = query.state.data
      const hasRunningMigrations = data?.some(
        m =>
          m.migration_progress?.workflow_state === 'running' ||
          m.migration_progress?.workflow_state === 'queued',
      )
      return hasRunningMigrations ? 5000 : false // Poll every 5 seconds if any migration is running or queued
    },
    enabled: !!rootAccountId,
  })
}

/**
 * Mutation hook to start a migration for a specific sub-account
 * Uses optimistic updates to immediately mark migration as clicked
 */
export const useMigrationMutation = (
  rootAccountId: string,
  options?: {onError?: (error: Error) => void},
) => {
  return useMutation({
    mutationFn: async ({subAccountId, email}: {subAccountId: string; email?: string}) => {
      const result = await doFetchApi({
        method: 'POST',
        path: `/api/v1/accounts/${subAccountId}/asset_processors/tii_migrations`,
        body: email ? {email} : undefined,
      })
      return result.json
    },
    onMutate: async ({subAccountId}) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({queryKey: ['tii_migrations', rootAccountId]})

      // Snapshot the previous value
      const previousMigrations = queryClient.getQueryData<TiiApMigration[]>([
        'tii_migrations',
        rootAccountId,
      ])

      // Optimistically update to the new value
      queryClient.setQueryData<TiiApMigration[]>(['tii_migrations', rootAccountId], old => {
        if (!old) return old
        return old.map(migration =>
          migration.account_id === subAccountId ? {...migration, migrateClicked: true} : migration,
        )
      })

      return {previousMigrations}
    },
    onSuccess: () => {
      // Invalidate the migrations list to refetch with new progress_id
      queryClient.invalidateQueries({queryKey: ['tii_migrations', rootAccountId]})
    },
    onError: (error, _variables, context) => {
      // Rollback to the previous value on error
      if (context?.previousMigrations) {
        queryClient.setQueryData(['tii_migrations', rootAccountId], context.previousMigrations)
      }
      options?.onError?.(error)
    },
  })
}

/**
 * Cancels all active migration queries
 * Useful for cleanup when modal is closed
 */
export const cancelMigrationQueries = (rootAccountId: string) => {
  queryClient.cancelQueries({queryKey: ['tii_migrations', rootAccountId]})
}
