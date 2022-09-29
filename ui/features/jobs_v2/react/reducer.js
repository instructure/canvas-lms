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

function setQargs(hash) {
  const params = new URLSearchParams(window.location.search)
  for (const [name, value] of Object.entries(hash)) {
    params.set(name, value)
  }
  window.history.replaceState('', '', `?${params.toString()}`)
}

export function initialState() {
  const params = new URLSearchParams(window.location.search)
  return {
    bucket: params.get('bucket') || 'running',
    group_text: params.get('group_text') || '',
    group_type: params.get('group_type') || 'tag',
    group_order: params.get('group_order') || 'info',
    jobs_order: params.get('jobs_order') || 'info',
    groups: [],
    jobs: [],
    job: null,
    jobs_loading: false,
    jobs_page: parseInt(params.get('jobs_page') || '1', 10),
    jobs_page_count: 1,
    jobs_refresh_nonce: 1,
    groups_loading: false,
    groups_page: parseInt(params.get('groups_page') || '1', 10),
    groups_page_count: 1,
    groups_refresh_nonce: 1,
    scope: params.get('scope') || Object.keys(ENV.jobs_scope_filter)[0],
    auto_refresh: (params.get('auto_refresh') || '0') !== '0',
    start_date: params.get('start_date'),
    end_date: params.get('end_date'),
    time_zone: params.get('time_zone') || ENV?.TIMEZONE || 'UTC',
  }
}

export function jobsReducer(prevState, action) {
  if (action.type === 'CHANGE_BUCKET') {
    setQargs({bucket: action.payload})
    return {
      ...prevState,
      bucket: action.payload,
      groups: [],
      jobs: [],
      job: null,
      groups_page: 1,
      jobs_page: 1,
      groups_page_count: 1,
      jobs_page_count: 1,
    }
  } else if (action.type === 'CHANGE_GROUP_TYPE') {
    setQargs({group_type: action.payload})
    return {
      ...prevState,
      group_type: action.payload,
      groups: [],
      jobs: [],
      job: null,
      groups_page: 1,
      jobs_page: 1,
      groups_page_count: 1,
      jobs_page_count: 1,
    }
  } else if (action.type === 'CHANGE_GROUP_ORDER') {
    setQargs({group_order: action.payload})
    return {...prevState, group_order: action.payload, groups: []}
  } else if (action.type === 'GROUPS_LOADING') {
    return {...prevState, groups_loading: action.payload}
  } else if (action.type === 'REFRESH_GROUPS') {
    return {...prevState, groups_refresh_nonce: prevState.groups_refresh_nonce + 1}
  } else if (action.type === 'FETCHED_GROUPS') {
    return {...prevState, groups: action.payload}
  } else if (action.type === 'GROUP_METADATA') {
    if (action.payload.link) {
      const last = parseInt(action.payload.link.last?.page, 10) || 1
      return {
        ...prevState,
        groups_page_count: last,
        groups_page: Math.min(prevState.groups_page, last),
      }
    }
  } else if (action.type === 'CHANGE_GROUPS_PAGE') {
    setQargs({groups_page: action.payload})
    return {...prevState, groups_page: action.payload}
  } else if (action.type === 'CHANGE_GROUP_TEXT') {
    if (prevState.group_text !== action.payload) {
      setQargs({group_text: action.payload})
      return {
        ...prevState,
        group_text: action.payload,
        jobs: [],
        job: null,
        jobs_page: 1,
        jobs_page_count: 1,
      }
    } else {
      return prevState
    }
  } else if (action.type === 'CHANGE_JOBS_ORDER') {
    setQargs({jobs_order: action.payload})
    return {...prevState, jobs_order: action.payload, jobs: [], job: null}
  } else if (action.type === 'JOBS_LOADING') {
    return {...prevState, jobs_loading: action.payload}
  } else if (action.type === 'REFRESH_JOBS') {
    return {...prevState, jobs_refresh_nonce: prevState.jobs_refresh_nonce + 1}
  } else if (action.type === 'FETCHED_JOBS') {
    const job = action.payload.find(j => j.id === prevState.job?.id) || prevState.job
    return {...prevState, jobs: action.payload, job}
  } else if (action.type === 'JOBS_METADATA') {
    if (action.payload.link) {
      const last = parseInt(action.payload.link.last?.page, 10) || 1
      return {
        ...prevState,
        jobs_page_count: last,
        jobs_page: Math.min(prevState.jobs_page, last),
      }
    }
  } else if (action.type === 'CHANGE_JOBS_PAGE') {
    setQargs({jobs_page: action.payload})
    return {...prevState, jobs_page: action.payload}
  } else if (action.type === 'SELECT_JOB') {
    return {...prevState, job: action.payload}
  } else if (action.type === 'CHANGE_SCOPE') {
    setQargs({jobs_scope: action.payload})
    return {
      ...prevState,
      groups: [],
      jobs: [],
      job: null,
      groups_page: 1,
      jobs_page: 1,
      groups_page_count: 1,
      jobs_page_count: 1,
      scope: action.payload,
    }
  } else if (action.type === 'TOGGLE_AUTO_REFRESH') {
    if (prevState.auto_refresh) {
      setQargs({auto_refresh: '0'})
      return {...prevState, auto_refresh: false}
    } else {
      setQargs({auto_refresh: '1'})
      return {
        ...prevState,
        auto_refresh: true,
        groups_refresh_nonce: prevState.groups_refresh_nonce + 1,
        jobs_refresh_nonce: prevState.jobs_refresh_nonce + 1,
      }
    }
  } else if (action.type === 'REFRESH_ALL') {
    return {
      ...prevState,
      groups_refresh_nonce: prevState.groups_refresh_nonce + 1,
      jobs_refresh_nonce: prevState.jobs_refresh_nonce + 1,
    }
  } else if (action.type === 'CHANGE_DATE_OPTIONS') {
    setQargs({
      start_date: action.payload.start_date || '',
      end_date: action.payload.end_date || '',
      time_zone: action.payload.time_zone,
    })
    if (
      action.payload.start_date !== prevState.start_date ||
      action.payload.end_date !== prevState.end_date
    ) {
      return {
        ...prevState,
        start_date: action.payload.start_date,
        end_date: action.payload.end_date,
        time_zone: action.payload.time_zone,
        groups: [],
        jobs: [],
        groups_page: 1,
        jobs_page: 1,
        groups_page_count: 1,
        jobs_page_count: 1,
      }
    } else {
      return {
        ...prevState,
        time_zone: action.payload.time_zone,
      }
    }
  }
}
