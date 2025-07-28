/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import type {PaginatedList} from './PaginatedList'
import type {AppsSortDirection, AppsSortProperty} from './registrations'

export const sampleAppNames = [
  'Aa reallly long name that is very long and has a lot of characters',
  'NetFriends',
  'Circlify',
  'InterLinked',
  'SocialNation',
  'Appmosphere',
  'NetworkingNexus',
  'Chatterboxx',
  'ShareWorldz',
  'Linkers',
  'Social Tap',
  'FeedFrenzy',
  'TweeterVille',
  'Apptology',
  'SocialNation',
  'LikeMinds',
  'LinkUp!',
  'FlairFriends',
  'Fun-Tastic!',
  'The Appsmiths',
  'CodeGenome',
  'Creative Bytes',
  'Mobile Dreamers',
  'AppConnected',
  'AppVentures',
  'Digital Dimensions',
  'CloudFamily Tree',
  'TapTap Wonderland and Apparatus.',
  'Appy Ever After',
  'Appalicious',
  'MyMobiApps',
  'Pixel Playground',
  'CloudKitten',
  'Sweet Apps',
  'Dottie Doodle',
  'Appsteroids Jr.',
  'MobileFamilies and Appersnappers.',
  'Appception',
  'MobileCelerate',
  'Crosslytics',
  'App-tacular!',
  'Design Republic',
  'DataRealm',
  'Bit Works',
  'The App Lounge',
  'ByteElements',
  'App-Tastic!',
  'Appsteroids',
  'Appaholics Anonymous',
  'Clicktacular!',
  'Pix-a-Frenzy',
  'TapTap Revolution',
  'SwipeLeft!',
  'Mobile Madness',
  'JetSet Apps',
  'OhSnap',
  'Mobile Tap',
  'Pixel Palooza',
  'Apptivate',
  'Cloud Crafty',
  'Mobilyze',
  'Appsolutely Fabulous',
  'LazyPixal',
  'Pocket Geeks',
  'Dot-Mania!',
  'SwipeRight!',
  'SecureMoney',
  'MoneyMinders',
  'CashConnected',
  'AppBanking',
  'PaySmartly',
  'FinTechRepublic',
  'Connect-Ease',
  'E-Budgetary',
  'MobileCashiers',
  'MoneyMapped',
  'Finsync.',
  'GameGeeks',
  'PlayNation',
  'AppVenturers',
  'KingdomQuest',
  'GameTime',
  'PixelPlayhouse',
  'AppVentures',
  'App-titude',
  'PlayQuest',
  'ArcadeNation',
  'GamersRUs.',
  'Shoptopia!',
  'StoreApptastic',
  'ShopConnected',
  'ApptasticShopper',
  'ShopMania!',
  'SmartBuyers',
  'MobileBoutique',
  'Buysterz',
  'GadgetFrenzy.',
  'FitFrenzy!',
  'ApptitudeFitness',
  'Move & Muscle',
  'FitConnected',
  'FitnessMania!',
  'WorkOutWorld',
  'ExerciseExpressions',
  'MobilizeMe!',
  'FitnessMapped',
  'SchedulingSurge',
  'App-tune-ments',
  'SyncSmartly',
  'ConnectSchedule',
  'OrganizedYou!',
  'TimeMappedMe!',
  'AppointmentEase',
  'TimeConnected',
  'ScheduleFrenzy!',
]

const deletedIds: LtiRegistrationId[] = []

const generateLtiRegistration = (id: string, name: string): any => ({
  id,
  account_id: id,
  icon_url: `/lti/tool_default_icon?id=${id}&name=${name}`,
  name,
  // admin_nickname: 'Admin Nickname 1',
  workflow_state: 'active',
  created_at: '2021-10-01T00:00:00Z',
  updated_at: '2021-10-01T00:00:00Z',
  created_by: id,
  updated_by: id,
  vendor: `Vendor ${id}`,
  internal_service: true,
  developer_key_id: id,
  ims_registration_id: id,
  manual_configuration_id: id,
  legacy_configuration_id: id,
  account_binding: {
    id,
    registration_id: id,
    account_id: id,
    workflow_state: 'active',
    created_at: '2021-10-01T00:00:00Z',
    updated_at: '2021-10-01T00:00:00Z',
    created_by: id,
    updated_by: id,
  },
})

// create array with 10 elements
// export const SampleLtiRegistrations: any[] = Array.from({length: 20}, (_, i) =>
//   generateLtiRegistration((i + 1).toString())
// )

export const SampleLtiRegistrations: any[] = [
  {
    id: '1',
    internal_service: false,
    icon_url: 'http://yaltt.inst.test/api/apps/1/icon.svg',
    // icon_url: 'https://cdn.edmentum.com/alvs/favicon.ico',
    account_id: '1',
    name: 'Yaltt',
    workflow_state: 'active',
    created_at: '2021-10-01T00:00:00Z',
    updated_at: '2021-10-01T00:00:00Z',
    created_by: '1',
    updated_by: '1',
    vendor: 'Vendor 1',
    developer_key_id: '1',
    ims_registration_id: '1',
    manual_configuration_id: '1',
    legacy_configuration_id: '1',
    account_binding: {
      id: '1',
      registration_id: '1',
      account_id: '1',
      workflow_state: 'active',
      created_at: '2021-10-01T00:00:00Z',
      updated_at: '2021-10-01T00:00:00Z',
      created_by: '1',
      updated_by: '1',
    },
  },
  ...sampleAppNames.map((name, i) => generateLtiRegistration((i + 2).toString(), name)),
]

/**
 * Returns a random integer between min (inclusive) and max (inclusive).
 * The value is no lower than min (or the next integer greater than min
 * if min isn't an integer) and no greater than max (or the next integer
 * lower than max if max isn't an integer).
 * Using Math.round() will give you a non-uniform distribution!
 */
function getRandomInt(min: number, max: number) {
  min = Math.ceil(min)
  max = Math.floor(max)
  return Math.floor(Math.random() * (max - min + 1)) + min
}

const getSampleRegistrationDb = async (options: {
  query: string
  sort: AppsSortProperty
  dir: AppsSortDirection
  limit: number
  offset: number
}): Promise<PaginatedList<any>> => {
  const registrations = SampleLtiRegistrations.filter(registration => {
    return registration.name.toLowerCase().includes(options.query.toLowerCase())
  })
    .filter(registration => !deletedIds.includes(registration.id))
    .sort((a, b) => {
      if (options.sort === 'name') {
        return a.name.localeCompare(b.name) * (options.dir === 'asc' ? 1 : -1)
      } else if (options.sort === 'nickname') {
        return (
          (a.admin_nickname || '').localeCompare(b.admin_nickname || '') *
          (options.dir === 'asc' ? 1 : -1)
        )
      } else if (options.sort === 'lti_version') {
        return (
          a.legacy_configuration_id.localeCompare(b.legacy_configuration_id) *
          (options.dir === 'asc' ? 1 : -1)
        )
      } else if (options.sort === 'installed') {
        return (
          a.account_binding.workflow_state.localeCompare(b.account_binding.workflow_state) *
          (options.dir === 'asc' ? 1 : -1)
        )
      } else if (options.sort === 'installed_by') {
        return a.created_by.localeCompare(b.created_by) * (options.dir === 'asc' ? 1 : -1)
      } else if (options.sort === 'on') {
        return a.created_at.localeCompare(b.created_at) * (options.dir === 'asc' ? 1 : -1)
      }
      return 0
    })
  const pagedRegistrations = registrations.slice(options.offset, options.offset + options.limit)
  return {
    data: pagedRegistrations,
    total: registrations.length,
  }
}

export const mockFetchSampleLtiRegistrations = async (options: {
  query: string
  sort: AppsSortProperty
  dir: AppsSortDirection
  offset: number
  limit: number
}): Promise<PaginatedList<any>> => {
  await wait(getRandomInt(1, 1) * 1000)
  return getSampleRegistrationDb(options)
}

export const mockDeleteRegistration = async (id: LtiRegistrationId): Promise<void> => {
  await wait((1 + Math.random()) * 1000)
  if (parseInt(id, 10) % 2 === 1) {
    throw new Error('Mock Delete Registration failure')
  } else {
    deletedIds.push(id)
  }
}

function wait(milliseconds: number) {
  return new Promise(resolve => setTimeout(resolve, milliseconds))
}
