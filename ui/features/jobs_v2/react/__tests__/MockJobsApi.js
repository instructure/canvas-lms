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

function fake_link_header(path) {
  return {
    current: {page: '1', url: `${path}?page=1`},
    next: {page: '2', url: `${path}?page=2`},
    last: {page: '5', url: `${path}?page=5`},
  }
}

function fake_info(bucket) {
  if (bucket === 'running' || bucket === 'queued') {
    return 100.0 // number of seconds
  } else {
    return '2022-04-02T13:00:00Z' // timestamp
  }
}

const fake_job = {
  id: '3606',
  priority: 20,
  attempts: 1,
  handler: 'fake_job_list_handler_value',
  last_error: 'fake_job_list_last_error_value',
  run_at: '2022-04-02T13:01:00Z',
  locked_at: '2022-04-02T13:02:00Z',
  failed_at: '2022-04-02T13:03:00Z',
  locked_by: 'job010001039065:12438',
  tag: 'fake_job_list_tag_value',
  max_attempts: 1,
  strand: 'fake_job_list_strand_value',
  shard_id: '1',
  original_job_id: '2838533',
  singleton: 'fake_job_list_singleton_value',
}

export default function mockJobsApi({path}) {
  const [bucket, group, search] = path.replace('/api/v1/jobs2/', '').split('/')
  if (search) {
    // search
    const json = {
      fake_group_search_value_1: 106,
      fake_group_search_value_2: 92,
    }
    return {json}
  } else if (group) {
    // grouped_info
    const json = [
      {
        count: 1,
        [group.replace('by_', '')]: 'fake_job_list_group_value',
        info: fake_info(bucket),
      },
    ]
    return {json, link: fake_link_header(`/api/v1/jobs2/${bucket}/${group}`)}
  } else if (bucket.match(/\d+/)) {
    // lookup
    const json = [
      {
        ...fake_job,
        bucket,
      },
    ]
    return {json}
  } else {
    // list
    const json = [
      {
        ...fake_job,
        info: fake_info(bucket),
      },
    ]
    return {json, link: fake_link_header(`/api/v1/jobs2/${bucket}`)}
  }
}
