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

const hasProp = {}.hasOwnProperty

function TurnitinSettings(options) {
  if (options == null) {
    options = {}
  }
  this.normalizeBoolean = this.normalizeBoolean.bind(this)
  this.present = this.present.bind(this)
  this.excludesSmallMatches = this.excludesSmallMatches.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.percent = this.percent.bind(this)
  this.words = this.words.bind(this)
  this.originalityReportVisibility = options.originality_report_visibility || 'immediate'
  this.sPaperCheck = this.normalizeBoolean(options.s_paper_check)
  this.internetCheck = this.normalizeBoolean(options.internet_check)
  this.excludeBiblio = this.normalizeBoolean(options.exclude_biblio)
  this.excludeQuoted = this.normalizeBoolean(options.exclude_quoted)
  this.journalCheck = this.normalizeBoolean(options.journal_check)
  this.excludeSmallMatchesType = options.exclude_small_matches_type
  this.excludeSmallMatchesValue = options.exclude_small_matches_value || 0
  this.submitPapersTo = options.hasOwnProperty('submit_papers_to')
    ? this.normalizeBoolean(options.submit_papers_to)
    : true
}

TurnitinSettings.prototype.words = function () {
  if (this.excludeSmallMatchesType === 'words') {
    return this.excludeSmallMatchesValue
  } else {
    return ''
  }
}

TurnitinSettings.prototype.percent = function () {
  if (this.excludeSmallMatchesType === 'percent') {
    return this.excludeSmallMatchesValue
  } else {
    return ''
  }
}

TurnitinSettings.prototype.toJSON = function () {
  return {
    s_paper_check: this.sPaperCheck,
    originality_report_visibility: this.originalityReportVisibility,
    internet_check: this.internetCheck,
    exclude_biblio: this.excludeBiblio,
    exclude_quoted: this.excludeQuoted,
    journal_check: this.journalCheck,
    exclude_small_matches_type: this.excludeSmallMatchesType,
    exclude_small_matches_value: this.excludeSmallMatchesValue,
    submit_papers_to: this.submitPapersTo,
  }
}

TurnitinSettings.prototype.excludesSmallMatches = function () {
  return !(this.excludeSmallMatchesType == null)
}

TurnitinSettings.prototype.present = function () {
  const json = {}
  const ref = this
  for (const key in ref) {
    if (!hasProp.call(ref, key)) continue
    const value = ref[key]
    json[key] = value
  }
  json.excludesSmallMatches = this.excludesSmallMatches()
  json.words = this.words()
  json.percent = this.percent()
  return json
}

TurnitinSettings.prototype.normalizeBoolean = function (value) {
  return ['1', true, 'true', 1].includes(value)
}

export default TurnitinSettings
