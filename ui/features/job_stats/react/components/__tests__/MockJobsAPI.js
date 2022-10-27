/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

function fakeLinkHeader(path) {
  return {
    current: {page: '1', url: `${path}?page=1`},
    last: {page: '1', url: `${path}?page=1`},
  }
}

// GET /api/v1/jobs2/clusters[?page=X]
const fakeCluster = [
  {
    id: '101',
    database_server_id: 'jobs1',
    block_stranded_shard_ids: ['2'],
    jobs_held_shard_ids: ['7', '9'],
    domain: 'jobs101.example.com',
    counts: {running: 86, queued: 7, future: 530, blocked: 9},
  },
]

// GET /api/v1/jobs2/clusters?job_shards[]=Y
const refreshedCluster = [
  {
    id: '101',
    database_server_id: 'jobs1',
    block_stranded_shard_ids: [],
    jobs_held_shard_ids: [],
    domain: 'jobs101.example.com',
    counts: {running: 1, queued: 10, future: 100, blocked: 0},
  },
]

// PUT /api/v1/jobs2/unstuck?job_shards[]=Y
const fakeUnstuckResult = {
  status: 'pending',
  progress: {
    id: '655',
    context_id: '1',
    context_type: 'User',
    user_id: null,
    tag: 'JobsV2Controller::run_unstucker!',
    completion: null,
    workflow_state: 'queued',
    created_at: '2022-10-14T23:12:45Z',
    updated_at: '2022-10-14T23:12:45Z',
    message: null,
    url: '/api/v1/progress/655',
  },
}

// GET /api/v1/progress/Z
const fakeProgressResult = {
  id: '655',
  context_id: '1',
  context_type: 'User',
  user_id: null,
  tag: 'JobsV2Controller::run_unstucker!',
  completion: 100.0,
  workflow_state: 'completed',
  created_at: '2022-10-14T23:12:45Z',
  updated_at: '2022-10-14T23:12:46Z',
  message: null,
  url: '/api/v1/progress/655',
}

// GET /api/v1/jobs2/stuck/strands?job_shard=W
// GET /api/v1/jobs2/stuck/singletons?job_shard=W
const fakeStuckResult = [
  {name: 'foo', count: 1},
  {name: 'baz', count: 2},
]

export default function mockJobsApi({path, params}) {
  if (path === '/api/v1/jobs2/clusters') {
    if (params.job_shards) {
      return Promise.resolve({json: refreshedCluster, link: fakeLinkHeader(path)})
    } else {
      return Promise.resolve({json: fakeCluster, link: fakeLinkHeader(path)})
    }
  } else if (path === '/api/v1/jobs2/unstuck') {
    return Promise.resolve({json: fakeUnstuckResult})
  } else if (path === '/api/v1/progress/655') {
    return Promise.resolve({json: fakeProgressResult})
  } else if (path === '/api/v1/jobs2/stuck/strands' || path === '/api/v1/jobs2/stuck/singletons') {
    return Promise.resolve({json: fakeStuckResult})
  } else {
    return Promise.resolve({status: 500, json: {message: 'unexpected API call'}})
  }
}
