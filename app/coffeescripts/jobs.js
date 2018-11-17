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

import I18n from 'i18n!jobs'

import $ from 'jquery'
import Slick from 'vendor/slickgrid'
import 'jquery.ajaxJSON'
import 'jqueryui/dialog'
/*
xsslint safeString.identifier klass d out_of runtime_string
*/

function fillin_job_data(job) {
  $('#show-job .show-field').each((idx, field) => {
    const field_name = field.id.replace('job-', '')
    $(field).text(job[field_name] || '')
  })
  $('#job-id-link').attr('href', `/jobs?flavor=id&q=${job.id}`)
}

let selected_job = null

class FlavorGrid {
  constructor(options, type_name, grid_name) {
    this.setTimer = this.setTimer.bind(this)
    this.saveSelection = this.saveSelection.bind(this)
    this.restoreSelection = this.restoreSelection.bind(this)
    this.refresh = this.refresh.bind(this)
    this.change_flavor = this.change_flavor.bind(this)
    this.options = options
    this.type_name = type_name
    this.grid_name = grid_name
    this.data = []
    this.$element = $(this.grid_name)
    setTimeout(this.refresh, 0)
    if (this.options.refresh_rate) {
      this.setTimer()
    }
    this.query = ''
  }

  setTimer() {
    return setTimeout(() => this.refresh(this.setTimer), this.options.refresh_rate)
  }

  saveSelection() {
    if (this.type_name === 'running') {
      this.oldSelected = {}
      return this.grid.getSelectedRows().map(row => (this.oldSelected[this.data[row].id] = true))
    }
  }

  restoreSelection() {
    if (this.type_name === 'running') {
      let index = 0
      const newSelected = []
      for (const item of this.data) {
        if (this.oldSelected[item.id]) {
          newSelected.push(index)
        }
        index += 1
      }
      this.restoringSelection = true
      this.grid.setSelectedRows(newSelected)
      return (this.restoringSelection = false)
    }
  }

  refresh(cb) {
    return this.$element.queue(() =>
      $.ajaxJSON(this.options.url, 'GET', {flavor: this.options.flavor, q: this.query}, data => {
        this.saveSelection()
        this.data.length = 0
        this.loading = {}
        for (const item of data[this.type_name]) {
          this.data.push(item)
        }
        if (data.total && data.total > this.data.length) {
          for (
            let i = this.data.length, end = data.total, asc = this.data.length <= end;
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

        if (typeof cb === 'function') {
          cb()
        }
        if (typeof this.updated === 'function') {
          this.updated()
        }
        return this.$element.dequeue()
      })
    )
  }

  change_flavor(flavor) {
    this.options.flavor = flavor
    this.grid.setSelectedRows([])
    return this.refresh()
  }

  grid_options() {
    return {rowHeight: 20}
  }

  init() {
    this.columns = this.build_columns()
    this.loading = {}
    this.grid = new Slick.Grid(this.grid_name, this.data, this.columns, this.grid_options())
    return this
  }
}

window.Jobs = class Jobs extends FlavorGrid {
  constructor(options, type_name = 'jobs', grid_name = '#jobs-grid') {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) {
        super()
      }
      const thisFn = (() => this).toString()
      const thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim()
      eval(`${thisName} = this;`)
    }
    this.show_search = this.show_search.bind(this)
    this.change_flavor = this.change_flavor.bind(this)
    this.attempts_formatter = this.attempts_formatter.bind(this)
    this.load = this.load.bind(this)
    this.id_formatter = this.id_formatter.bind(this)
    if (options.max_attempts) {
      Jobs.max_attempts = options.max_attempts
    }
    super(options, type_name, grid_name)
    if (options.starting_query) {
      this.query = options.starting_query
    }
    this.show_search($('#jobs-flavor').val())
  }

  search(query) {
    this.query = query
    return this.refresh()
  }

  show_search(flavor) {
    switch (flavor) {
      case 'id':
      case 'strand':
      case 'tag':
        $('#jobs-search').show()
        $('#jobs-search').attr('placeholder', flavor)
      default:
        $('#jobs-search').hide()
    }
  }

  change_flavor(flavor) {
    this.show_search(flavor)
    return super.change_flavor(flavor)
  }

  attempts_formatter(r, c, d) {
    let klass
    if (!this.data[r].id) {
      return ''
    }
    const max = this.data[r].max_attempts || Jobs.max_attempts
    if (d === 0) {
      klass = ''
    } else if (d < max) {
      klass = 'has-failed-attempts'
    } else if (d === this.options.on_hold_attempt_count) {
      klass = 'on-hold'
      d = 'hold'
    } else {
      klass = 'has-failed-max-attempts'
    }
    const out_of = d === 'hold' ? '' : `/ ${max}`
    return `<span class='${klass}'>${d}${out_of}</span>`
  }

  load(row) {
    return this.$element.queue(() => {
      row -= row % this.options.limit
      if (this.loading[row]) {
        this.$element.dequeue()
        return
      }
      this.loading[row] = true
      return $.ajaxJSON(
        this.options.url,
        'GET',
        {flavor: this.options.flavor, q: this.query, offset: row},
        data => {
          this.data.splice(
            row,
            row + data[this.type_name].length - row,
            ...[].concat(data[this.type_name])
          )
          this.grid.invalidate()
          return this.$element.dequeue()
        }
      )
    })
  }

  id_formatter(r, c, d) {
    if (this.data[r].id) {
      return this.data[r].id
    } else {
      this.load(r)
      return "<span class='unloaded-id'>-</span>"
    }
  }

  build_columns() {
    return [
      {
        id: 'id',
        name: I18n.t('columns.id', 'id'),
        field: 'id',
        width: 100,
        formatter: this.id_formatter
      },
      {
        id: 'tag',
        name: I18n.t('columns.tag', 'tag'),
        field: 'tag',
        width: 200
      },
      {
        id: 'attempts',
        name: I18n.t('columns.attempt', 'attempt'),
        field: 'attempts',
        width: 65,
        formatter: this.attempts_formatter
      },
      {
        id: 'priority',
        name: I18n.t('columns.priority', 'priority'),
        field: 'priority',
        width: 60
      },
      {
        id: 'strand',
        name: I18n.t('columns.strand', 'strand'),
        field: 'strand',
        width: 100
      },
      {
        id: 'run_at',
        name: I18n.t('columns.run_at', 'run at'),
        field: 'run_at',
        width: 165
      }
    ]
  }

  init() {
    super.init()
    this.grid.setSelectionModel(new Slick.RowSelectionModel())
    this.grid.onSelectedRowsChanged.subscribe(() => {
      if (this.restoringSelection) return
      const rows = this.grid.getSelectedRows()
      const row = (rows != null ? rows.length : undefined) === 1 ? rows[0] : -1
      selected_job = this.data[rows[0]] || {}
      return fillin_job_data(selected_job)
    })
    return this
  }

  selectAll() {
    this.grid.setSelectedRows(__range__(0, this.data.length, false))
    return this.grid.onSelectedRowsChanged.notify()
  }

  onSelected(action) {
    const params = {
      flavor: this.options.flavor,
      q: this.query,
      update_action: action
    }

    if (this.grid.getSelectedRows().length < 1) {
      alert('No jobs are selected')
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
              'Are you sure you want to hold *all* jobs of this type and matching this query?'
            )
          case 'unhold':
            return I18n.t(
              'confirm.unhold_all',
              'Are you sure you want to unhold *all* jobs of this type and matching this query?'
            )
          case 'destroy':
            return I18n.t(
              'confirm.destroy_all',
              'Are you sure you want to destroy *all* jobs of this type and matching this query?'
            )
        }
      })()
      if (!confirm(message)) return
    }

    // special case -- if they've selected all, then don't send the ids so that
    // we can operate on jobs that match the query but haven't even been loaded
    // yet
    if (!all_jobs) {
      params.job_ids = this.grid.getSelectedRows().map(row => this.data[row].id)
    }

    $.ajaxJSON(this.options.batch_update_url, 'POST', params, this.refresh)
    return this.grid.setSelectedRows([])
  }

  updated() {
    $('#jobs-total').text(this.data.length)
    if (this.data.length === 1 && this.type_name === 'jobs') {
      this.grid.setSelectedRows([0])
      return this.grid.onSelectedRowsChanged.notify()
    }
  }

  getFullJobDetails(cb) {
    if (!selected_job || selected_job.handler) {
      return cb()
    } else {
      return $.ajaxJSON(
        `${this.options.job_url}/${selected_job.id}`,
        'GET',
        {flavor: this.options.flavor},
        data => {
          selected_job.handler = data.handler
          selected_job.last_error = data.last_error
          fillin_job_data(selected_job)
          return cb()
        }
      )
    }
  }
}

class Workers extends Jobs {
  constructor(options) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) {
        super()
      }
      const thisFn = (() => this).toString()
      const thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim()
      eval(`${thisName} = this;`)
    }
    this.runtime_formatter = this.runtime_formatter.bind(this)
    super(options, 'running', '#running-grid')
  }

  runtime_formatter(r, c, d) {
    let klass
    const runtime = (new Date() - Date.parse(d)) / 1000
    if (runtime >= this.options.super_slow_threshold) {
      klass = 'super-slow'
    } else if (runtime > this.options.slow_threshold) {
      klass = 'slow'
    } else {
      klass = ''
    }
    let format = 'HH:mm:ss'
    if (runtime > 86400) {
      format = 'd\\dHH:mm:ss'
    }
    let runtime_string = new Date(null, null, null, null, null, runtime).toString(format)
    if (runtime > 86400 * 28) {
      runtime_string = 'FOREVA'
    }
    return `<span class='${klass}'>${runtime_string}</span>`
  }

  build_columns() {
    const cols = [
      {
        id: 'worker',
        name: I18n.t('columns.worker', 'worker'),
        field: 'locked_by',
        width: 90
      }
    ].concat(super.build_columns())
    cols.pop()
    cols.push({
      id: 'runtime',
      name: I18n.t('columns.runtime', 'runtime'),
      field: 'locked_at',
      width: 85,
      formatter: this.runtime_formatter
    })
    for (const col of cols) {
      col.sortable = true
    }
    return cols
  }

  updated() {}

  init() {
    super.init()
    this.sort = (event, data) => {
      this.sortData = data
      if (event) {
        this.saveSelection()
      }
      const {field} = data.sortCol

      this.data.sort((a, b) => {
        let result
        const aField = a[field] || ''
        const bField = b[field] || ''
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
    return (this.sortData = {
      sortCol: {
        field: 'locked_at'
      },
      sortAsc: false
    })
  }
}

class Tags extends FlavorGrid {
  constructor(options) {
    super(options, 'tags', '#tags-grid')
  }

  build_columns() {
    return [
      {
        id: 'tag',
        name: I18n.t('columns.tag', 'tag'),
        field: 'tag',
        width: 200
      },
      {
        id: 'count',
        name: I18n.t('columns.count', 'count'),
        field: 'count',
        width: 50
      }
    ]
  }

  grid_options() {
    return $.extend(super.grid_options(), {enableCellNavigation: false})
  }

  init() {
    super.init()
    this.grid.setSelectionModel(new Slick.RowSelectionModel())
    return this
  }
}

$.extend(window, {
  Jobs,
  Workers,
  Tags
})

$(document).ready(() => {
  $('#tags-flavor').change(function() {
    return window.tags.change_flavor($(this).val())
  })
  $('#jobs-flavor').change(function() {
    return window.jobs.change_flavor($(this).val())
  })

  $('#jobs-refresh').click(() => window.jobs.refresh())

  const search_event = $('#jobs-search')[0].onsearch === undefined ? 'change' : 'search'
  $('#jobs-search').bind(search_event, function() {
    return window.jobs.search($(this).val())
  })

  $('#select-all-jobs').click(() => window.jobs.selectAll())

  $('#hold-jobs').click(() => window.jobs.onSelected('hold'))
  $('#un-hold-jobs').click(() => window.jobs.onSelected('unhold'))
  $('#delete-jobs').click(() => window.jobs.onSelected('destroy'))

  $('#job-handler-show').click(() => {
    window.jobs.getFullJobDetails(() =>
      $('#job-handler-wrapper')
        .clone()
        .dialog({
          title: I18n.t('titles.job_handler', 'Job Handler'),
          width: 900,
          height: 700,
          modal: true
        })
    )
    return false
  })

  $('#job-last_error-show').click(() => {
    window.jobs.getFullJobDetails(() =>
      $('#job-last_error-wrapper')
        .clone()
        .dialog({
          title: I18n.t('titles.last_error', 'Last Error'),
          width: 900,
          height: 700,
          modal: true
        })
    )
    return false
  })
})

export default {Jobs, Workers, Tags}

function __range__(left, right, inclusive) {
  const range = []
  const ascending = left < right
  const end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
