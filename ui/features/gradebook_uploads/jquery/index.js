/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, find, every} from 'lodash'
import htmlEscape from '@instructure/html-escape'
import numberHelper from '@canvas/i18n/numberHelper'
import {waitForProcessing} from './wait_for_processing'
import ProcessGradebookUpload from './process_gradebook_upload'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import 'slickgrid' /* global Slick */
import 'slickgrid/slick.editors' /* global.Slick.Editors */
import '@canvas/jquery/jquery.instructure_forms' /* errorBox */
import '@canvas/jquery/jquery.instructure_misc_helpers' /* /\.detect/ */
import '@canvas/util/templateData'

const I18n = useI18nScope('gradebook_uploads')
/* fillTemplateData */

function shouldHighlightScoreChange(oldValue, newValue) {
  // Even if canvas is operating in a locale that does commas as
  // the decimal separator, the text that represents the score
  // is sent period separated.
  const originalGrade = Number.parseFloat(oldValue)
  const updatedGrade = Number.parseFloat(newValue)
  const updateWillRemoveGrade = !Number.isNaN(originalGrade) && Number.isNaN(updatedGrade)

  return originalGrade > updatedGrade || updateWillRemoveGrade
}

const GradebookUploader = {
  createGeneralFormatter(attribute) {
    return function (row, cell, value) {
      return value ? htmlEscape(value[attribute]) : ''
    }
  },

  createGrid($container, {data, columns, options}) {
    return new Slick.Grid($container, data, columns, options)
  },

  createNumberFormatter(attribute) {
    return function (row, cell, value) {
      return value ? GradeFormatHelper.formatGrade(value[attribute]) : ''
    }
  },

  init(uploadedGradebook) {
    const $gradebook_grid = $('#gradebook_grid')
    const $gradebook_grid_header = $('#gradebook_grid_header')
    const rowsToHighlight = []

    let gradebookGrid

    const gridData = {
      columns: [
        {
          id: 'student',
          name: I18n.t('student', 'Student'),
          field: 'student',
          width: 250,
          cssClass: 'cell-title',
          formatter: GradebookUploader.createGeneralFormatter('name'),
        },
      ],
      options: {
        enableAddRow: false,
        editable: true,
        enableColumnReorder: false,
        asyncEditorLoading: true,
        rowHeight: 30,
      },
      data: [],
    }

    const labelData = {
      columns: [
        {
          id: 'assignmentGrouping',
          name: '',
          field: 'assignmentGrouping',
          width: 250,
        },
      ],
      options: {
        enableAddRow: false,
        enableColumnReorder: false,
        asyncEditorLoading: false,
      },
      data: [],
    }

    delete uploadedGradebook.missing_objects
    delete uploadedGradebook.original_submissions

    $.each(uploadedGradebook.assignments, function () {
      const newGrade = {
        id: this.id,
        type: 'assignments',
        name: htmlEscape(I18n.t('To')),
        field: this.id,
        width: 125,
        editor: Slick.Editors.UploadGradeCellEditor,
        formatter: GradebookUploader.createNumberFormatter('grade'),
        active: true,
        previous_id: this.previous_id,
        cssClass: 'new-grade',
      }

      if (this.grading_type !== 'letter_grade') {
        newGrade.editorFormatter = function (grade) {
          return GradeFormatHelper.formatGrade(grade, {defaultValue: ''})
        }
        newGrade.editorParser = GradeFormatHelper.delocalizeGrade
      }

      const conflictingGrade = {
        id: `${this.id}_conflicting`,
        width: 125,
        formatter: GradebookUploader.createNumberFormatter('original_grade'),
        field: `${this.id}_conflicting`,
        name: htmlEscape(I18n.t('From')),
        cssClass: 'conflicting-grade',
      }

      const assignmentHeaderColumn = {
        id: this.id,
        width: 250,
        name: htmlEscape(this.title),
        headerCssClass: 'assignment',
      }

      labelData.columns.push(assignmentHeaderColumn)
      gridData.columns.push(conflictingGrade)
      gridData.columns.push(newGrade)
    })

    uploadedGradebook.custom_columns.forEach(column => {
      const newCustomColumn = {
        id: `custom_col_${column.id}`,
        customColumnId: column.id,
        type: 'custom_column',
        name: htmlEscape(I18n.t('To')),
        field: `custom_col_${column.id}`,
        width: 125,
        editor: Slick.Editors.UploadGradeCellEditor,
        formatter: GradebookUploader.createGeneralFormatter('new_content'),
        editorFormatter: 'custom_column',
        editorParser: 'custom_column',
        active: true,
        cssClass: 'new-grade',
      }

      const conflictingCustomColumn = {
        id: `custom_col_${column.id}_conflicting`,
        width: 125,
        formatter: GradebookUploader.createGeneralFormatter('current_content'),
        field: `custom_col_${column.id}_conflicting`,
        name: htmlEscape(I18n.t('From')),
        cssClass: 'conflicting-grade',
      }

      const customColumnHeaderColumn = {
        id: `custom_col_${column.id}`,
        width: 250,
        name: htmlEscape(column.title),
        headerCssClass: 'assignment',
      }

      labelData.columns.push(customColumnHeaderColumn)
      gridData.columns.push(conflictingCustomColumn)
      gridData.columns.push(newCustomColumn)
    })

    if (uploadedGradebook.override_scores != null) {
      const overrideScores = uploadedGradebook.override_scores
      if (overrideScores.includes_course_scores) {
        this.addOverrideScoreChangeColumn(labelData, gridData)
      }

      overrideScores.grading_periods.forEach(gradingPeriod => {
        this.addOverrideScoreChangeColumn(labelData, gridData, gradingPeriod)
      })
    }
    if (uploadedGradebook.override_statuses != null) {
      const overrideStatuses = uploadedGradebook.override_statuses
      if (overrideStatuses.includes_course_score_status) {
        this.addOverrideStatusChangeColumn(labelData, gridData)
      }

      overrideStatuses.grading_periods.forEach(gradingPeriod => {
        this.addOverrideStatusChangeColumn(labelData, gridData, gradingPeriod)
      })
    }

    $.each(uploadedGradebook.students, function (index) {
      const row = {
        student: this,
        id: this.id,
      }
      $.each(this.submissions, function () {
        if (
          shouldHighlightScoreChange(this.original_grade, this.grade) &&
          (this.grade || '').toUpperCase() !== 'EX'
        ) {
          rowsToHighlight.push({rowIndex: index, id: this.assignment_id})
        }

        row.assignmentId = this.assignment_id
        row[this.assignment_id] = this
        row[`${this.assignment_id}_conflicting`] = this
      })
      $.each(this.custom_column_data, function () {
        if (this.current_content !== this.new_content) {
          rowsToHighlight.push({rowIndex: index, id: `custom_col_${this.column_id}`})
        }
        row[`custom_col_${this.column_id}`] = this
        row[`custom_col_${this.column_id}_conflicting`] = this
      })

      const currentStudent = this
      currentStudent.override_scores?.forEach(overrideScore => {
        const id = overrideScore.grading_period_id || 'course'
        const columnId = `override_score_${id}`

        if (shouldHighlightScoreChange(overrideScore.current_score, overrideScore.new_score)) {
          rowsToHighlight.push({rowIndex: index, id: columnId})
        }
        row[columnId] = overrideScore
        row[`${columnId}_conflicting`] = overrideScore
      })

      currentStudent.override_statuses?.forEach(overrideStatus => {
        const id = overrideStatus.grading_period_id || 'course'
        const columnId = `override_status_${id}`

        if (
          overrideStatus.current_grade_status !== null &&
          overrideStatus.current_grade_status?.toLowerCase() !==
            overrideStatus.new_grade_status?.toLowerCase()
        ) {
          rowsToHighlight.push({rowIndex: index, id: columnId})
        }
        row[columnId] = overrideStatus
        row[`${columnId}_conflicting`] = overrideStatus
      })

      gridData.data.push(row)
      row.active = true
    })

    // if there are still assignments with changes detected.
    if (gridData.columns.length > 1) {
      if (uploadedGradebook.unchanged_assignments) {
        $('#assignments_without_changes_alert').show()
      }

      const $gradebookGridForm = $('#gradebook_grid_form')
      $gradebookGridForm
        .submit(e => {
          e.preventDefault()
          $gradebookGridForm.disableWhileLoading(ProcessGradebookUpload.upload(uploadedGradebook))
        })
        .show()

      $(window)
        .resize(() => {
          $gradebook_grid.height($(window).height() - $gradebook_grid.offset().top - 150)
          const width = (gridData.columns.length - 1) * 125 + 250
          $gradebook_grid.parent().width(width)
        })
        .triggerHandler('resize')

      gradebookGrid = GradebookUploader.createGrid($gradebook_grid, gridData)
      GradebookUploader.createGrid($gradebook_grid_header, labelData)

      const gradeReviewRow = {}

      for (let i = 0; i < rowsToHighlight.length; i++) {
        const id = rowsToHighlight[i].id
        const rowIndex = rowsToHighlight[i].rowIndex
        const conflictingId = `${id}_conflicting`

        gradeReviewRow[rowIndex] = gradeReviewRow[rowIndex] || {}
        gradeReviewRow[rowIndex][id] = 'right-highlight'
        gradeReviewRow[rowIndex][conflictingId] = 'left-highlight'
        gradebookGrid.invalidateRow(rowIndex)
      }

      gradebookGrid.setCellCssStyles('highlight-grade-change', gradeReviewRow)
      gradebookGrid.render()
    } else {
      $('#no_changes_detected').show()
    }

    if (uploadedGradebook.warning_messages.prevented_new_assignment_creation_in_closed_period) {
      $('#prevented-new-assignment-in-closed-period').show()
    }

    if (uploadedGradebook.warning_messages.prevented_grading_ungradeable_submission) {
      $('#prevented-grading-ungradeable-submission').show()
    }

    if (uploadedGradebook.warning_messages.prevented_changing_read_only_column) {
      $('#prevented_changing_read_only_column').show()
    }
  },

  handleThingsNeedingToBeResolved() {
    return waitForProcessing(ENV.progress)
      .then(uploadedGradebook => {
        processUploadedGradebook(uploadedGradebook)
      })
      .catch(error => {
        alert(error.message)
        window.location = ENV.new_gradebook_upload_path
      })

    function processUploadedGradebook(uploadedGradebook) {
      const needingReview = {}

      // first, figure out if there is anything that needs to be resolved
      $.each(['student', 'assignment'], (i, thing) => {
        const $template = $(`#${thing}_resolution_template`).remove(),
          $select = $template.find('select')

        needingReview[thing] = []

        $.each(uploadedGradebook[`${thing}s`], function () {
          if (!this.previous_id) {
            needingReview[thing].push(this)
          }
        })

        if (needingReview[thing].length) {
          $select.change(function () {
            $(this).next('.points_possible_section').css({opacity: 0})
            if ($(this).val() > 0) {
              // if the thing that was selected is an id( not ignore or add )
              $(`#${thing}_resolution_template select option`).removeAttr('disabled')
              $(`#${thing}_resolution_template select`).each(function () {
                if ($(this).val() !== 'ignore') {
                  $(`#${thing}_resolution_template select`)
                    .not(this)
                    .find(`option[value='${$(this).val()}']`)
                    .prop('disabled', true)
                }
              })
            } else if ($(this).val() === 'new') {
              $(this).next('.points_possible_section').css({opacity: 1})
            }
          })

          $.each(uploadedGradebook.missing_objects[`${thing}s`], function () {
            $(
              `<option value="${this.id}" >${htmlEscape(this.name || this.title)}</option>`
            ).appendTo($select)
          })

          $.each(needingReview[thing], (i, record) => {
            $template
              .clone(true)
              .fillTemplateData({
                iterator: record.id,
                data: {
                  name: record.name,
                  title: record.title,
                  points_possible: I18n.n(record.points_possible),
                },
              })
              .appendTo(`#gradebook_importer_resolution_section .${thing}_section table tbody`)
              .show()
              .find('input.points_possible')
              .change(function () {
                const $this = $(this)
                record.points_possible = numberHelper.parse($this.val())
                $this.val(I18n.n(record.points_possible))
              })
          })
          $(
            `#gradebook_importer_resolution_section, #gradebook_importer_resolution_section .${thing}_section`
          ).show()
        }
      })
      // end figuring out if thigs need to be resolved

      if (needingReview.student.length || needingReview.assignment.length) {
        // if there are things that need to be resolved, set up stuff for that form
        $('#gradebook_importer_resolution_section').submit(function (e) {
          let returnFalse = false
          e.preventDefault()

          $(this)
            .find('select')
            .each(function () {
              if (!$(this).val()) {
                returnFalse = true
                $(this).errorBox(I18n.t('errors.select_an_option', 'Please select an option'))
                return false
              }
            })
          if (returnFalse) return false

          $(this)
            .find('select')
            .each(function () {
              const $select = $(this),
                parts = $select.attr('name').split('_'),
                thing = parts[0],
                id = parts[1],
                val = $select.val()

              switch (val) {
                case 'new':
                  // do nothing
                  break
                case 'ignore':
                  // remove the entry from the uploaded gradebook
                  for (const i in uploadedGradebook[`${thing}s`]) {
                    if (id == uploadedGradebook[`${thing}s`][i].id) {
                      uploadedGradebook[`${thing}s`].splice(i, 1)
                      break
                    }
                  }
                  break
                default: {
                  // merge
                  const obj = find(uploadedGradebook[`${thing}s`], thng => id == thng.id)
                  obj.id = obj.previous_id = val
                  if (thing === 'assignment') {
                    // find the original grade for this assignment for each student
                    $.each(uploadedGradebook.students, function () {
                      const student = this
                      const submission = find(student.submissions, thng => thng.assignment_id == id)
                      submission.assignment_id = val
                      const original_submission = find(
                        uploadedGradebook.original_submissions,
                        sub => sub.user_id == student.id && sub.assignment_id == val
                      )
                      if (original_submission) {
                        submission.original_grade =
                          original_submission.score !== '' ? I18n.n(original_submission.score) : ''
                      }
                    })
                  } else if (thing === 'student') {
                    // find the original grade for each assignment for this student
                    $.each(obj.submissions, function () {
                      const submission = this
                      const original_submission = find(
                        uploadedGradebook.original_submissions,
                        sub =>
                          sub.user_id == obj.id && sub.assignment_id == submission.assignment_id
                      )
                      if (original_submission) {
                        submission.original_grade =
                          original_submission.score !== '' ? I18n.n(original_submission.score) : ''
                      }
                    })
                  }
                }
              }
            })

          // remove assignments that have no changes
          const indexes_to_delete = []
          $.each(uploadedGradebook.assignments, index => {
            if (
              uploadedGradebook.assignments[index].previous_id &&
              every(uploadedGradebook.students, student => {
                const submission = student.submissions[index]

                return (
                  parseFloat(submission.original_grade) == parseFloat(submission.grade) ||
                  (!submission.original_grade && !submission.grade)
                )
              })
            ) {
              indexes_to_delete.push(index)
            }
          })
          each(indexes_to_delete.reverse(), index => {
            uploadedGradebook.assignments.splice(index, 1)
            $.each(uploadedGradebook.students, function () {
              this.submissions.splice(index, 1)
            })
          })
          if (indexes_to_delete.length != 0) {
            uploadedGradebook.unchanged_assignments = true
          }

          $(this).hide()
          GradebookUploader.init(uploadedGradebook)
        })
      } else {
        // if there is nothing that needs to resolved, just skip to initialize slick grid.
        GradebookUploader.init(uploadedGradebook)
      }
    }
  },

  addOverrideScoreChangeColumn(labelData, gridData, gradingPeriod = null) {
    // A null grading period means these changes are for override grades for the course
    const id = gradingPeriod?.id || 'course'
    const title = gradingPeriod?.title
      ? I18n.t('Override Score (%{gradingPeriod})', {gradingPeriod: gradingPeriod.title})
      : I18n.t('Override Score')

    const newOverrideScoreColumn = {
      id: `override_score_${id}`,
      type: 'assignment',
      name: htmlEscape(I18n.t('To')),
      field: `override_score_${id}`,
      width: 125,
      editor: Slick.Editors.UploadGradeCellEditor,
      editorFormatter: 'override_score',
      editorParser: 'override_score',
      formatter: GradebookUploader.createNumberFormatter('new_score'),
      active: true,
      cssClass: 'new-grade',
    }

    const conflictingOverrideScoreColumn = {
      id: `override_score_${id}_conflicting`,
      width: 125,
      formatter: GradebookUploader.createNumberFormatter('current_score'),
      field: `override_score_${id}_conflicting`,
      name: htmlEscape(I18n.t('From')),
      cssClass: 'conflicting-grade',
    }
    gridData.columns.push(conflictingOverrideScoreColumn, newOverrideScoreColumn)

    const overrideScoreHeaderColumn = {
      id: `override_score_${id}`,
      width: 250,
      name: htmlEscape(title),
      headerCssClass: 'assignment',
    }
    labelData.columns.push(overrideScoreHeaderColumn)
  },

  addOverrideStatusChangeColumn(labelData, gridData, gradingPeriod = null) {
    // A null grading period means these changes are for override grades for the course
    const id = gradingPeriod?.id || 'course'
    const title = gradingPeriod?.title
      ? I18n.t('Override Status (%{gradingPeriod})', {gradingPeriod: gradingPeriod.title})
      : I18n.t('Override Status')

    const newOverrideStatusColumn = {
      id: `override_status_${id}`,
      type: 'assignment',
      name: htmlEscape(I18n.t('To')),
      field: `override_status_${id}`,
      width: 125,
      editor: Slick.Editors.UploadGradeCellEditor,
      editorFormatter: 'override_status',
      editorParser: 'override_status',
      formatter: GradebookUploader.createGeneralFormatter('new_grade_status'),
      active: true,
      cssClass: 'new-grade',
    }

    const conflictingOverrideScoreColumn = {
      id: `override_status_${id}_conflicting`,
      width: 125,
      formatter: GradebookUploader.createGeneralFormatter('current_grade_status'),
      field: `override_status_${id}_conflicting`,
      name: htmlEscape(I18n.t('From')),
      cssClass: 'conflicting-grade',
    }
    gridData.columns.push(conflictingOverrideScoreColumn, newOverrideStatusColumn)

    const overrideScoreHeaderColumn = {
      id: `override_status_${id}`,
      width: 250,
      name: htmlEscape(title),
      headerCssClass: 'assignment',
    }
    labelData.columns.push(overrideScoreHeaderColumn)
  },
}

export default GradebookUploader
