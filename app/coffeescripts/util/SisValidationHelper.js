//
// Copyright (C) 2017 - present Instructure, Inc.
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

export default class SisValidationHelper {
  constructor (params) {
    this.postToSIS = params.postToSIS
    this.allDates = params.allDates
    this.dueDateRequired = params.dueDateRequired
    this.maxNameLengthRequired = params.maxNameLengthRequired
    this.dueDate = params.dueDate
    this.modelName = params.name
    this.maxNameLength = params.maxNameLength
  }

  nameTooLong () {
    if (!this.postToSIS) return false
    if (this.maxNameLengthRequired) {
      return this.nameLengthComparison()
    } else if (!this.maxNameLengthRequired && this.maxNameLength === 256) {
      return this.nameLengthComparison()
    }
  }

  nameLengthComparison () {
    return this.modelName.length > this.maxNameLength
  }

  dueAtNotValid (date) {
    if(!date) return true
    return (date.dueAt === null || date.dueAt === undefined || date.dueAt === '')
  }

  dueDateMissingDifferentiated () {
    if (!this.allDates) return false
    return (this.allDates.map(this.dueAtNotValid).indexOf(true) !== -1)
  }

  baseDueDateMissing () {
    return ((!this.allDates || this.allDates.length === 0) && !this.dueDate)
  }

  dueDateMissing () {
    if (!this.postToSIS) return false
    return this.dueDateRequired && (this.baseDueDateMissing() || this.dueDateMissingDifferentiated())
  }
}
