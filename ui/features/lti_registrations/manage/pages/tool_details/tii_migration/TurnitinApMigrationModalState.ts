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

const ZCoordinatorProgress = z.object({
  id: z.string(),
  workflow_state: z.enum(['running', 'completed', 'failed', 'queued']),
  consolidated_report_url: z.string().nullish(),
})

const ZMigrationResponse = z.object({
  accounts: z.array(ZTiiApMigration),
  coordinator_progress: ZCoordinatorProgress.nullish(),
})

export type TiiApMigration = z.infer<typeof ZTiiApMigration> & {
  migrateClicked?: boolean
}
export type TiiApMigrationProgress = z.infer<typeof ZTiiApMigrationProgress>
export type CoordinatorProgress = z.infer<typeof ZCoordinatorProgress>
export type MigrationResponse = z.infer<typeof ZMigrationResponse>

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
        ZMigrationResponse,
      )
      return result.json
    },
    staleTime: 0,
    refetchInterval: query => {
      const data = query.state.data
      const hasRunningMigrations = data?.accounts.some(
        m =>
          m.migration_progress?.workflow_state === 'running' ||
          m.migration_progress?.workflow_state === 'queued',
      )
      const coordinatorRunning =
        data?.coordinator_progress?.workflow_state === 'running' ||
        data?.coordinator_progress?.workflow_state === 'queued'
      return hasRunningMigrations || coordinatorRunning ? 5000 : false // Poll every 5 seconds if any migration is running or queued
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
      const previousData = queryClient.getQueryData<MigrationResponse>([
        'tii_migrations',
        rootAccountId,
      ])

      // Optimistically update to the new value
      queryClient.setQueryData<MigrationResponse>(['tii_migrations', rootAccountId], old => {
        if (!old) return old
        return {
          ...old,
          accounts: old.accounts.map(migration =>
            migration.account_id === subAccountId
              ? {...migration, migrateClicked: true}
              : migration,
          ),
        }
      })

      return {previousData}
    },
    onSuccess: () => {
      // Invalidate the migrations list to refetch with new progress_id
      queryClient.invalidateQueries({queryKey: ['tii_migrations', rootAccountId]})
    },
    onError: (error, _variables, context) => {
      // Rollback to the previous value on error
      if (context?.previousData) {
        queryClient.setQueryData(['tii_migrations', rootAccountId], context.previousData)
      }
      options?.onError?.(error)
    },
  })
}

/**
 * Mutation hook to start migrations for all sub-accounts at once
 */
export const useMigrateAllMutation = (
  rootAccountId: string,
  options?: {onError?: (error: Error) => void},
) => {
  return useMutation({
    mutationFn: async ({email}: {email?: string}) => {
      const result = await doFetchApi({
        method: 'POST',
        path: `/api/v1/accounts/${rootAccountId}/asset_processors/tii_migrations/migrate_all`,
        body: email ? {email} : undefined,
      })
      return result.json
    },
    onMutate: async () => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({queryKey: ['tii_migrations', rootAccountId]})

      // Snapshot the previous value
      const previousData = queryClient.getQueryData<MigrationResponse>([
        'tii_migrations',
        rootAccountId,
      ])

      // Optimistically update coordinator progress to running
      queryClient.setQueryData<MigrationResponse>(['tii_migrations', rootAccountId], old => {
        if (!old) return old
        return {
          ...old,
          coordinator_progress: old.coordinator_progress
            ? {...old.coordinator_progress, workflow_state: 'running' as const}
            : {id: 'pending', workflow_state: 'running' as const},
        }
      })

      return {previousData}
    },
    onSuccess: () => {
      // Invalidate to refetch with new progress for all accounts
      queryClient.invalidateQueries({queryKey: ['tii_migrations', rootAccountId]})
    },
    onError: (error, _variables, context) => {
      // Rollback to the previous value on error
      if (context?.previousData) {
        queryClient.setQueryData(['tii_migrations', rootAccountId], context.previousData)
      }
      options?.onError?.(error)
    },
  })
}

/**
 * Helper to determine if any migrations are eligible for "Migrate All"
 * Returns true if there are 2 or more migrations that haven't started or have failed
 */
export const hasEligibleMigrations = (data?: MigrationResponse): boolean => {
  const migrations = data?.accounts
  if (!migrations || migrations.length === 0) return false

  const eligibleCount = migrations.filter(m => {
    const state = m.migration_progress?.workflow_state
    // Eligible if no progress yet, or if migration failed (can retry)
    return !state || state === 'failed'
  }).length

  return eligibleCount > 1
}

/**
 * Helper to check if bulk migration is in progress
 * Considers it bulk if more than one migration is queued/running at same time
 */
export const isBulkMigrationInProgress = (data?: MigrationResponse): boolean => {
  const migrations = data?.accounts
  if (!migrations || migrations.length === 0) return false

  // Count active migrations (queued or running)
  const activeCount = migrations.filter(m => {
    const state = m.migration_progress?.workflow_state
    return state === 'queued' || state === 'running'
  }).length

  return activeCount > 1
}

/**
 * Cancels all active migration queries
 * Useful for cleanup when modal is closed
 */
export const cancelMigrationQueries = (rootAccountId: string) => {
  queryClient.cancelQueries({queryKey: ['tii_migrations', rootAccountId]})
}
