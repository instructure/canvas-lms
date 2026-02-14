//
// Copyright (C) 2011 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {createRoot} from 'react-dom/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {JobDialog} from '../react/components'
import ready from '@instructure/ready'
import $ from 'jquery'
import Slick from 'slickgrid'

const I18n = createI18nScope('jobs')
/*
xsslint safeString.identifier klass d out_of runtime_string
*/

interface Job {
  id?: string | number
  tag?: string
  attempts?: number
  max_attempts?: number
  priority?: number
  strand?: string
  singleton?: string
  run_at?: string
  locked_by?: string
  locked_at?: string
  handler?: string
  last_error?: string
}

interface FlavorGridOptions {
  url: string
  flavor: string
  refresh_rate?: number
  limit: number
  on_hold_attempt_count?: number
  batch_update_url?: string
  job_url?: string
  starting_query?: string
  max_attempts?: number
  super_slow_threshold?: number
  slow_threshold?: number
}

interface SortData {
  sortCol: {field: string}
  sortAsc: boolean
}

function __range__(left: number, right: number, inclusive: boolean): number[] {
  const range: number[] = []
  const ascending = left < right
  const end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) range.push(i)
  return range
}

function fillin_job_data(job: Job) {
  $('#show-job .show-field').each((_idx, field) => {
    const field_name = field.id.replace('job-', '')
    $(field).text((job as any)[field_name] || '')
  })
  $('#job-id-link').attr('href', `/jobs?flavor=id&q=${job.id}`)
}

let selected_job: Job | null = null

class FlavorGrid {
  options: FlavorGridOptions
  type_name: string
  grid_name: string
  data: Job[]
  $element: JQuery
  query: string
  grid!: any
  loading: Record<number, boolean>
  oldSelected?: Record<string | number, boolean>
  restoringSelection?: boolean
  sortData?: SortData
  updated(): void {}

  constructor(options: FlavorGridOptions, type_name: string, grid_name: string) {
    this.options = options
    this.type_name = type_name
    this.grid_name = grid_name
    this.data = []
    this.$element = $(this.grid_name)
    this.loading = {}
    requestAnimationFrame(this.refresh as unknown as FrameRequestCallback)
    if (this.options.refresh_rate) this.setTimer()
    this.query = ''
  }

  setTimer = (): ReturnType<typeof setTimeout> => {
    return setTimeout(() => this.refresh(this.setTimer), this.options.refresh_rate)
  }

  saveSelection = (): void => {
    if (this.type_name === 'running') {
      this.oldSelected = {}
      this.grid.getSelectedRows().map((row: number) => {
        const id = this.data[row]?.id
        if (id !== undefined) {
          this.oldSelected![id] = true
        }
      })
    }
  }

  restoreSelection = (): void => {
    if (this.type_name === 'running' && this.oldSelected) {
      let index = 0
      const newSelected: number[] = []
      for (const item of this.data) {
        if (item.id !== undefined && this.oldSelected[item.id]) {
          newSelected.push(index)
        }
        index += 1
      }
      this.restoringSelection = true
      this.grid.setSelectedRows(newSelected)
      this.restoringSelection = false
    }
  }

  refresh = (cb?: () => void): JQuery => {
    return this.$element.queue(() => {
      doFetchApi({
        path: this.options.url,
        params: {
          flavor: this.options.flavor,
          q: this.query,
        },
      })
        .then(response => {
          const {json} = response as {json: any}
          this.saveSelection()
          this.data.length = 0
          this.loading = {}
          for (const item of json[this.type_name]) {
            this.data.push(item)
          }
          if (json.total && json.total > this.data.length) {
            for (
              let i = this.data.length, end = json.total, asc = this.data.length <= end;
              asc ? i < end : i > end;
              asc ? i++ : i--
            ) {
              this.data.push({})
            }
          }

          if (this.sortData) {
            this.sort(null, this.sortData)
          } else {
            this.grid.invalidate()
            this.restoreSelection()
          }

          // eslint-disable-next-line promise/no-callback-in-promise
          if (typeof cb === 'function') cb()
          if (typeof this.updated === 'function') this.updated()
          this.$element.dequeue()
        })
        .catch((error: Error) => {
          console.info('Error fetching data:', error)
          this.$element.dequeue()
        })
    })
  }

  change_flavor(flavor: string): JQuery {
    this.options.flavor = flavor
    this.grid.setSelectedRows([])
    return this.refresh()
  }

  grid_options(): {rowHeight: number} {
    return {rowHeight: 20}
  }

  sort(_event: any, _data: SortData): void {
    // Override in subclasses
  }

  build_columns(): any[] {
    return []
  }

  init(): this {
    this.columns = this.build_columns()
    this.loading = {}
    this.grid = new Slick.Grid(this.grid_name, this.data, this.columns, this.grid_options())
    return this
  }

  columns: any[] = []
}

class Jobs extends FlavorGrid {
  static max_attempts: number

  constructor(options: FlavorGridOptions, type_name = 'jobs', grid_name = '#jobs-grid') {
    if (options.max_attempts) {
      Jobs.max_attempts = options.max_attempts
    }
    super(options, type_name, grid_name)
    if (options.starting_query) {
      this.query = options.starting_query
    }
    this.show_search((document.getElementById('jobs-flavor') as HTMLSelectElement)?.value)
  }

  search(query: string): JQuery {
    this.query = query
    return this.refresh()
  }

  show_search(flavor: string): void {
    const jobsSearch = document.getElementById('jobs-search') as HTMLInputElement
    if (!jobsSearch) return
    switch (flavor) {
      case 'id':
      case 'strand':
      case 'tag':
        jobsSearch.style.display = ''
        jobsSearch.setAttribute('placeholder', flavor)
        break
      default:
        jobsSearch.style.display = 'none'
    }
  }

  change_flavor(flavor: string): JQuery {
    this.show_search(flavor)
    return super.change_flavor(flavor)
  }

  attempts_formatter(r: number, _c: number, d: number | string): string {
    let klass: string
    if (!this.data[r]?.id) return ''
    const max = this.data[r]?.max_attempts || Jobs.max_attempts
    if (d === 0) klass = ''
    else if (typeof d === 'number' && d < max) klass = 'has-failed-attempts'
    else if (d === this.options.on_hold_attempt_count) {
      klass = 'on-hold'
      d = 'hold'
    } else klass = 'has-failed-max-attempts'
    const out_of = d === 'hold' ? '' : `/ ${max}`
    return `<span class='${klass}'>${d}${out_of}</span>`
  }

  load(row: number): JQuery {
    return this.$element.queue(() => {
      row -= row % this.options.limit
      if (this.loading[row]) {
        this.$element.dequeue()
        return
      }
      this.loading[row] = true
      doFetchApi({
        path: this.options.url,
        params: {
          flavor: this.options.flavor,
          q: this.query,
          offset: row,
        },
      })
        .then(response => {
          const {json} = response as {json: any}
          this.data.splice(
            row,
            row + json[this.type_name].length - row,
            ...[].concat(json[this.type_name]),
          )
          this.grid.invalidate()
          this.$element.dequeue()
        })
        .catch((error: Error) => {
          console.info('Error loading data:', error)
          this.$element.dequeue()
        })
    })
  }

  id_formatter(r: number, _c: number, _d: any): string {
    if (this.data[r]?.id) {
      return String(this.data[r].id)
    } else {
      this.load(r)
      return "<span class='unloaded-id'>-</span>"
    }
  }

  build_columns(): any[] {
    return [
      {
        id: 'id',
        name: I18n.t('columns.id', 'id'),
        field: 'id',
        width: 100,
        formatter: this.id_formatter.bind(this),
      },
      {
        id: 'tag',
        name: I18n.t('columns.tag', 'tag'),
        field: 'tag',
        width: 200,
      },
      {
        id: 'attempts',
        name: I18n.t('columns.attempt', 'attempt'),
        field: 'attempts',
        width: 65,
        formatter: this.attempts_formatter.bind(this),
      },
      {
        id: 'priority',
        name: I18n.t('columns.priority', 'priority'),
        field: 'priority',
        width: 60,
      },
      {
        id: 'strand',
        name: I18n.t('columns.strand', 'strand'),
        field: 'strand',
        width: 100,
      },
      {
        id: 'singleton',
        name: I18n.t('columns.singleton', 'singleton'),
        field: 'singleton',
        width: 100,
      },
      {
        id: 'run_at',
        name: I18n.t('columns.run_at', 'run at'),
        field: 'run_at',
        width: 165,
      },
    ]
  }

  init(): this {
    super.init()
    this.grid.setSelectionModel(new Slick.RowSelectionModel())
    this.grid.onSelectedRowsChanged.subscribe(() => {
      if (this.restoringSelection) return
      const rows = this.grid.getSelectedRows()
      selected_job = this.data[rows[0]] || null
      if (selected_job) {
        return fillin_job_data(selected_job)
      }
    })
    return this
  }

  selectAll(): void {
    this.grid.setSelectedRows(__range__(0, this.data.length, false))
    this.grid.onSelectedRowsChanged.notify()
  }

  onSelected(action: 'hold' | 'unhold' | 'destroy'): void {
    const params: any = {
      flavor: this.options.flavor,
      q: this.query,
      update_action: action,
    }

    if (this.grid.getSelectedRows().length < 1) {
      window.alert('No jobs are selected')
      return
    }

    const all_jobs =
      this.grid.getSelectedRows().length > 1 &&
      this.grid.getSelectedRows().length === this.data.length

    if (all_jobs) {
      const message = (() => {
        switch (action) {
          case 'hold':
            return I18n.t(
              'confirm.hold_all',
              'Are you sure you want to hold *all* jobs of this type and matching this query?',
            )
          case 'unhold':
            return I18n.t(
              'confirm.unhold_all',
              'Are you sure you want to unhold *all* jobs of this type and matching this query?',
            )
          case 'destroy':
            return I18n.t(
              'confirm.destroy_all',
              'Are you sure you want to destroy *all* jobs of this type and matching this query?',
            )
        }
      })()

      if (!window.confirm(message)) return
    }

    // special case -- if they've selected all, then don't send the ids so that
    // we can operate on jobs that match the query but haven't even been loaded
    // yet
    if (!all_jobs) {
      params.job_ids = this.grid.getSelectedRows().map((row: number) => this.data[row]?.id)
    }

    doFetchApi({
      path: this.options.batch_update_url!,
      method: 'POST',
      body: params,
    })
      .then(() => this.refresh())
      .catch((error: Error) => console.error('Error updating jobs:', error))

    this.grid.setSelectedRows([])
  }

  updated(): void {
    const jobsTotal = document.getElementById('jobs-total')
    if (jobsTotal) jobsTotal.textContent = String(this.data.length)
    if (this.data.length === 1 && this.type_name === 'jobs') {
      this.grid.setSelectedRows([0])
      this.grid.onSelectedRowsChanged.notify()
    }
  }

  async getFullJobDetails(): Promise<Job | null> {
    if (!selected_job || selected_job.handler) return Promise.resolve(selected_job)

    try {
      const response = await doFetchApi({
        path: `${this.options.job_url}/${selected_job.id}`,
        params: {flavor: this.options.flavor},
      })
      const {json} = response as {json: any}
      selected_job.handler = json.handler
      selected_job.last_error = json.last_error
      fillin_job_data(selected_job)
      return selected_job
    } catch (error) {
      console.info('Error fetching job details:', error)
      return selected_job
    }
  }
}

;(window as any).Jobs = Jobs

class Workers extends Jobs {
  constructor(options: FlavorGridOptions) {
    super(options, 'running', '#running-grid')
  }

  runtime_formatter(_r: number, _c: number, d: string): string {
    let klass: string
    const runtime = (new Date().getTime() - Date.parse(d)) / 1000
    if (this.options.super_slow_threshold && runtime >= this.options.super_slow_threshold)
      klass = 'super-slow'
    else if (this.options.slow_threshold && runtime > this.options.slow_threshold) klass = 'slow'
    else klass = ''
    let format = 'HH:mm:ss'
    if (runtime > 86400) format = 'd\\dHH:mm:ss'
    let runtime_string = new Date(0, 0, 0, 0, 0, runtime).toString(format)
    if (runtime > 86400 * 28) runtime_string = 'FOREVA'
    return `<span class='${klass}'>${runtime_string}</span>`
  }

  build_columns(): any[] {
    const cols = [
      {
        id: 'worker',
        name: I18n.t('columns.worker', 'worker'),
        field: 'locked_by',
        width: 90,
      },
    ].concat(super.build_columns())
    cols.pop()
    cols.push({
      id: 'runtime',
      name: I18n.t('columns.runtime', 'runtime'),
      field: 'locked_at',
      width: 85,
      // @ts-expect-error - SlickGrid formatter property
      formatter: this.runtime_formatter.bind(this),
    })
    // @ts-expect-error - SlickGrid column property
    for (const col of cols) col.sortable = true
    return cols
  }

  updated(): void {}

  init(): this {
    super.init()
    this.sort = (event: any, data: SortData) => {
      this.sortData = data
      if (event) {
        this.saveSelection()
      }
      const {field} = data.sortCol

      this.data.sort((a, b) => {
        let result: number
        const aField = (a as any)[field] || ''
        const bField = (b as any)[field] || ''
        if (aField > bField) {
          result = 1
        } else if (aField < bField) {
          result = -1
        } else {
          result = 0
        }

        if (!data.sortAsc) {
          result = -result
        }
        if (field === 'locked_at') {
          result = -result
        }
        return result
      })

      this.grid.invalidate()
      return this.restoreSelection()
    }
    this.grid.onSort.subscribe(this.sort)
    this.grid.setSortColumn('runtime', false)
    this.sortData = {
      sortCol: {
        field: 'locked_at',
      },
      sortAsc: false,
    }
    return this
  }
}

class Tags extends FlavorGrid {
  constructor(options: FlavorGridOptions) {
    super(options, 'tags', '#tags-grid')
  }

  build_columns(): any[] {
    return [
      {
        id: 'tag',
        name: I18n.t('columns.tag', 'tag'),
        field: 'tag',
        width: 200,
      },
      {
        id: 'count',
        name: I18n.t('columns.count', 'count'),
        field: 'count',
        width: 50,
      },
    ]
  }

  grid_options(): any {
    return $.extend(super.grid_options(), {enableCellNavigation: false})
  }

  init(): this {
    super.init()
    this.grid.setSelectionModel(new Slick.RowSelectionModel())
    return this
  }
}

$.extend(window, {Jobs, Workers, Tags})

ready(() => {
  $('#tags-flavor').on('change', function () {
    return (window as any).tags.change_flavor($(this).val())
  })
  $('#jobs-flavor').on('change', function () {
    return (window as any).jobs.change_flavor($(this).val())
  })

  $('#jobs-refresh').on('click', () => (window as any).jobs.refresh())

  const search_event = ($('#jobs-search')[0] as any).onsearch === undefined ? 'change' : 'search'
  $('#jobs-search').on(search_event, function () {
    return (window as any).jobs.search($(this).val() as string)
  })

  $('#select-all-jobs').on('click', () => (window as any).jobs.selectAll())
  $('#hold-jobs').on('click', () => (window as any).jobs.onSelected('hold'))
  $('#un-hold-jobs').on('click', () => (window as any).jobs.onSelected('unhold'))
  $('#delete-jobs').on('click', () => (window as any).jobs.onSelected('destroy'))

  const jobHandlerContainer = document.getElementById('job-handler-wrapper')
  if (jobHandlerContainer) {
    const root = createRoot(jobHandlerContainer)
    root.render(
      <JobDialog
        label={I18n.t('Job Handler')}
        retrieveValue={async () => {
          const job = await (window as any).jobs.getFullJobDetails()
          return job?.handler || ''
        }}
      />,
    )
  }

  const jobLastErrorContainer = document.getElementById('job-last_error-wrapper')
  if (jobLastErrorContainer) {
    const root = createRoot(jobLastErrorContainer)
    root.render(
      <JobDialog
        label={I18n.t('Last Error')}
        retrieveValue={async () => {
          const job = await (window as any).jobs.getFullJobDetails()
          return job?.last_error || ''
        }}
      />,
    )
  }
})

export default {Jobs, Workers, Tags}
