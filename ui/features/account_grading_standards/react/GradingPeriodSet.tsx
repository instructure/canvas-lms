/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import $ from 'jquery'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconTrashLine, IconPlusLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import axios from '@canvas/axios'
import {useScope as createI18nScope} from '@canvas/i18n'
import GradingPeriod from './AccountGradingPeriod'
import GradingPeriodForm from './GradingPeriodForm'
import gradingPeriodsApi from '@canvas/grading/jquery/gradingPeriodsApi'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import type {GradingPeriodInput} from '@canvas/grading/jquery/gradingPeriodsApi'
import type {
  EnrollmentTerm,
  GradingPeriod as SavedGradingPeriod,
  GradingPeriodDraft,
  GradingPeriodSet as GradingPeriodSetType,
  GradingPeriodsUrls,
  Permissions,
} from './types'

const I18n = createI18nScope('GradingPeriodSet')

const sortPeriods = function (periods: SavedGradingPeriod[]): SavedGradingPeriod[] {
  return [...periods].sort((a, b) => b.startDate.getTime() - a.startDate.getTime()).reverse()
}

const anyPeriodsOverlap = function (periods: GradingPeriodDraft[]): boolean {
  if (periods.length < 2) {
    return false
  }

  for (let i = 0; i < periods.length; i += 1) {
    const first = periods[i]
    if (!first.startDate || !first.endDate) continue

    for (let j = i + 1; j < periods.length; j += 1) {
      const other = periods[j]
      if (!other.startDate || !other.endDate) continue

      if (other.startDate < first.endDate && first.startDate < other.endDate) {
        return true
      }
    }
  }

  return false
}

const isValidDate = function (date: Date | null): date is Date {
  if (!(date instanceof Date)) return false
  return !Number.isNaN(date.getTime())
}

const validatePeriods = function (periods: GradingPeriodDraft[], weighted: boolean): string[] {
  if (periods.some(period => !(period.title || '').trim())) {
    return [I18n.t('All grading periods must have a title')]
  }

  if (
    weighted &&
    periods.some(
      period => period.weight == null || Number.isNaN(period.weight) || period.weight < 0,
    )
  ) {
    return [I18n.t('All weights must be greater than or equal to 0')]
  }

  const validDates = periods.every(
    period =>
      isValidDate(period.startDate) && isValidDate(period.endDate) && isValidDate(period.closeDate),
  )

  if (!validDates) {
    return [I18n.t('All dates fields must be present and formatted correctly')]
  }

  const orderedStartAndEndDates = periods.every(
    period => !!period.startDate && !!period.endDate && period.startDate < period.endDate,
  )

  if (!orderedStartAndEndDates) {
    return [I18n.t('All start dates must be before the end date')]
  }

  const orderedEndAndCloseDates = periods.every(
    period => !!period.endDate && !!period.closeDate && period.endDate <= period.closeDate,
  )

  if (!orderedEndAndCloseDates) {
    return [I18n.t('All close dates must be on or after the end date')]
  }

  if (anyPeriodsOverlap(periods)) {
    return [I18n.t('Grading periods must not overlap')]
  }

  return []
}

const isEditingPeriod = function (state: GradingPeriodSetState): boolean {
  return !!state.editPeriod.id
}

const isActionsDisabled = function (
  state: GradingPeriodSetState,
  props: GradingPeriodSetProps,
): boolean {
  return !!(props.actionsDisabled || isEditingPeriod(state) || state.newPeriod.period)
}

const getShowGradingPeriodRef = function (period: SavedGradingPeriod): string {
  return `show-grading-period-${period.id}`
}

interface NewPeriodState {
  period: GradingPeriodDraft | null
  saving: boolean
}

interface EditPeriodState {
  id: string | null
  saving: boolean
}

interface GradingPeriodSetProps {
  gradingPeriods: SavedGradingPeriod[]
  terms: EnrollmentTerm[]
  readOnly: boolean
  expanded?: boolean
  actionsDisabled?: boolean
  onEdit: (set: GradingPeriodSetType) => void
  onDelete: (setId: string) => void
  onPeriodsChange: (setId: string, periods: SavedGradingPeriod[]) => void
  onToggleBody: () => void
  set: GradingPeriodSetType
  urls: GradingPeriodsUrls
  permissions: Permissions
}

interface GradingPeriodSetState {
  title: string
  weighted: boolean
  displayTotalsForAllGradingPeriods: boolean
  gradingPeriods: SavedGradingPeriod[]
  newPeriod: NewPeriodState
  editPeriod: EditPeriodState
}

interface GradingPeriodRowRef {
  _refs?: {
    editButton?: Element | null
  }
}

interface GradingPeriodSetRefs {
  addPeriodButton?: Element | null
  [key: string]: unknown
}

export default class GradingPeriodSet extends React.Component<
  GradingPeriodSetProps,
  GradingPeriodSetState
> {
  _refs: GradingPeriodSetRefs

  constructor(props: GradingPeriodSetProps) {
    super(props)
    this.state = {
      title: this.props.set.title,
      weighted: !!this.props.set.weighted,
      displayTotalsForAllGradingPeriods: this.props.set.displayTotalsForAllGradingPeriods,
      gradingPeriods: sortPeriods(this.props.gradingPeriods),
      newPeriod: {
        period: null,
        saving: false,
      },
      editPeriod: {
        id: null,
        saving: false,
      },
    }
    this._refs = {}
  }

  componentDidUpdate(_prevProps: GradingPeriodSetProps, prevState: GradingPeriodSetState) {
    if (prevState.newPeriod.period && !this.state.newPeriod.period) {
      ;(this._refs.addPeriodButton as HTMLElement | null)?.focus()
    } else if (isEditingPeriod(prevState) && !isEditingPeriod(this.state)) {
      const periodRef = this._refs[
        `show-grading-period-${prevState.editPeriod.id}`
      ] as GradingPeriodRowRef
      ;(periodRef?._refs?.editButton as HTMLElement | null)?.focus()
    }
  }

  toggleSetBody = () => {
    if (!isEditingPeriod(this.state)) {
      this.props.onToggleBody()
    }
  }

  promptDeleteSet = (event: React.SyntheticEvent<unknown>) => {
    event.stopPropagation()
    const confirmMessage = I18n.t('Are you sure you want to delete this grading period set?')
    if (!window.confirm(confirmMessage)) return

    const url = `${this.props.urls.gradingPeriodSetsURL}/${this.props.set.id}`
    axios
      .delete(url)
      .then(() => {
        $.flashMessage(I18n.t('The grading period set was deleted'))
        this.props.onDelete(this.props.set.id)
      })
      .catch(() => {
        $.flashError(I18n.t('An error occured while deleting the grading period set'))
      })
  }

  setTerms = (): EnrollmentTerm[] =>
    this.props.terms.filter(term => term.gradingPeriodGroupId === this.props.set.id)

  termNames = () => {
    const names = this.setTerms().map(term => term.displayName ?? term.name)
    if (names.length > 0) {
      return I18n.t('Terms: ') + names.join(', ')
    }

    return I18n.t('No Associated Terms')
  }

  editSet = (e: React.SyntheticEvent<unknown>) => {
    e.stopPropagation()
    this.props.onEdit(this.props.set)
  }

  changePeriods = (periods: SavedGradingPeriod[]) => {
    const sortedPeriods = sortPeriods(periods)
    this.setState({gradingPeriods: sortedPeriods})
    this.props.onPeriodsChange(this.props.set.id, sortedPeriods)
  }

  removeGradingPeriod = (idToRemove: string) => {
    this.setState(oldState => {
      const gradingPeriods = oldState.gradingPeriods.filter(period => period.id !== idToRemove)
      return {gradingPeriods}
    })
  }

  showNewPeriodForm = () => {
    this.setNewPeriod({
      period: {title: '', weight: null, startDate: null, endDate: null, closeDate: null},
    })
  }

  saveNewPeriod = (period: GradingPeriodDraft) => {
    const periods: GradingPeriodInput[] = [...this.state.gradingPeriods, period]
    const validations = validatePeriods(periods, this.state.weighted)
    if (validations.length === 0) {
      this.setNewPeriod({saving: true})
      gradingPeriodsApi
        .batchUpdate(this.props.set.id, periods)
        .then((pds: SavedGradingPeriod[]) => {
          $.flashMessage(I18n.t('All changes were saved'))
          this.removeNewPeriodForm()
          this.changePeriods(pds)
        })
        .catch(_err => {
          $.flashError(I18n.t('There was a problem saving the grading period'))
          this.setNewPeriod({saving: false})
        })
    } else {
      validations.forEach(message => {
        $.flashError(message)
      })
    }
  }

  removeNewPeriodForm = () => {
    this.setNewPeriod({saving: false, period: null})
  }

  setNewPeriod = (attr: Partial<NewPeriodState>) => {
    this.setState(oldState => ({newPeriod: {...oldState.newPeriod, ...attr}}))
  }

  editPeriod = (period: SavedGradingPeriod) => {
    this.setEditPeriod({id: period.id ?? null, saving: false})
  }

  updatePeriod = (period: GradingPeriodDraft) => {
    const existing = this.state.gradingPeriods.filter(_period => period.id !== _period.id)
    const periods: GradingPeriodInput[] = [...existing, period]
    const validations = validatePeriods(periods, this.state.weighted)
    if (validations.length === 0) {
      this.setEditPeriod({saving: true})
      gradingPeriodsApi
        .batchUpdate(this.props.set.id, periods)
        .then((pds: SavedGradingPeriod[]) => {
          $.flashMessage(I18n.t('All changes were saved'))
          this.setEditPeriod({id: null, saving: false})
          this.changePeriods(pds)
        })
        .catch(_err => {
          $.flashError(I18n.t('There was a problem saving the grading period'))
          this.setNewPeriod({saving: false})
        })
    } else {
      validations.forEach(message => {
        $.flashError(message)
      })
    }
  }

  cancelEditPeriod = () => {
    this.setEditPeriod({id: null, saving: false})
  }

  setEditPeriod = (attr: Partial<EditPeriodState>) => {
    this.setState(oldState => ({editPeriod: {...oldState.editPeriod, ...attr}}))
  }

  renderEditButton = () => {
    if (!this.props.readOnly && this.props.permissions.update) {
      const disabled = isActionsDisabled(this.state, this.props)
      return (
        <IconButton
          elementRef={ref => {
            this._refs.editButton = ref
          }}
          disabled={disabled}
          withBackground={false}
          withBorder={false}
          onClick={this.editSet}
          title={I18n.t('Edit %{title}', {title: this.props.set.title})}
          screenReaderLabel={I18n.t('Edit %{title}', {title: this.props.set.title})}
        >
          <IconEditLine />
        </IconButton>
      )
    }

    return null
  }

  renderDeleteButton = () => {
    if (!this.props.readOnly && this.props.permissions.delete) {
      const disabled = isActionsDisabled(this.state, this.props)
      return (
        <IconButton
          elementRef={ref => {
            this._refs.deleteButton = ref
          }}
          disabled={disabled}
          onClick={this.promptDeleteSet}
          withBackground={false}
          withBorder={false}
          title={I18n.t('Delete %{title}', {title: this.props.set.title})}
          screenReaderLabel={I18n.t('Delete %{title}', {title: this.props.set.title})}
        >
          <IconTrashLine />
        </IconButton>
      )
    }

    return null
  }

  renderEditAndDeleteButtons = () => (
    <div className="ItemGroup__header__admin">
      {this.renderEditButton()}
      {this.renderDeleteButton()}
    </div>
  )

  renderSetBody = () => {
    if (!this.props.expanded) return null

    return (
      <div
        ref={ref => {
          this._refs.setBody = ref
        }}
        className="ig-body"
      >
        <div
          className="GradingPeriodList"
          ref={ref => {
            this._refs.gradingPeriodList = ref
          }}
        >
          {this.renderGradingPeriods()}
        </div>
        {this.renderNewPeriod()}
      </div>
    )
  }

  renderGradingPeriods = () => {
    const actionsDisabled = isActionsDisabled(this.state, this.props)
    return this.state.gradingPeriods.map(period => {
      const periodId = period.id ?? `${period.title}-${period.startDate.toISOString()}`
      if (period.id === this.state.editPeriod.id) {
        return (
          <div
            key={`edit-grading-period-${periodId}`}
            className="GradingPeriodList__period--editing pad-box"
          >
            <GradingPeriodForm
              ref={ref => {
                this._refs.editPeriodForm = ref
              }}
              period={period}
              weighted={this.state.weighted}
              disabled={this.state.editPeriod.saving}
              onSave={this.updatePeriod}
              onCancel={this.cancelEditPeriod}
            />
          </div>
        )
      }

      return (
        <GradingPeriod
          key={`show-grading-period-${periodId}`}
          ref={ref => {
            this._refs[getShowGradingPeriodRef(period)] = ref
          }}
          period={period as SavedGradingPeriod & {id: string}}
          weighted={this.state.weighted}
          actionsDisabled={actionsDisabled}
          onEdit={this.editPeriod}
          readOnly={this.props.readOnly}
          onDelete={this.removeGradingPeriod}
          deleteGradingPeriodURL={this.props.urls.deleteGradingPeriodURL}
          permissions={this.props.permissions}
        />
      )
    })
  }

  renderNewPeriod = () => {
    if (this.props.permissions.create && !this.props.readOnly) {
      if (this.state.newPeriod.period) {
        return this.renderNewPeriodForm()
      }

      return this.renderNewPeriodButton()
    }

    return null
  }

  renderNewPeriodButton = () => {
    const disabled = isActionsDisabled(this.state, this.props)
    return (
      <div className="GradingPeriodList__new-period center-xs border-rbl border-round-b">
        <Link
          as="button"
          elementRef={ref => {
            this._refs.addPeriodButton = ref
          }}
          disabled={disabled}
          aria-label={I18n.t('Add Grading Period')}
          onClick={this.showNewPeriodForm}
          renderIcon={IconPlusLine}
        >
          {I18n.t('Grading Period')}
        </Link>
      </div>
    )
  }

  renderNewPeriodForm = () => (
    <div className="GradingPeriodList__new-period--editing border border-rbl border-round-b pad-box">
      <GradingPeriodForm
        key="new-grading-period"
        ref={ref => {
          this._refs.newPeriodForm = ref
        }}
        period={this.state.newPeriod.period ?? undefined}
        weighted={this.state.weighted}
        disabled={this.state.newPeriod.saving}
        onSave={this.saveNewPeriod}
        onCancel={this.removeNewPeriodForm}
      />
    </div>
  )

  render() {
    const setStateSuffix = this.props.expanded ? 'expanded' : 'collapsed'
    const arrow = this.props.expanded ? 'down' : 'right'
    return (
      <div className={`GradingPeriodSet--${setStateSuffix}`}>
        {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events,jsx-a11y/no-static-element-interactions */}
        <div
          className="ItemGroup__header"
          ref={ref => {
            this._refs.toggleSetBody = ref
          }}
          onClick={this.toggleSetBody}
        >
          <div>
            <div className="ItemGroup__header__title">
              <button
                type="button"
                className="Button Button--icon-action GradingPeriodSet__toggle"
                aria-expanded={this.props.expanded}
                aria-label={I18n.t('Toggle %{title} grading period visibility', {
                  title: this.props.set.title,
                })}
              >
                <i className={`icon-mini-arrow-${arrow}`} />
              </button>
              <h2
                ref={ref => {
                  this._refs.title = ref
                }}
                className="GradingPeriodSet__title"
              >
                {this.props.set.title}
              </h2>
            </div>
            {this.renderEditAndDeleteButtons()}
          </div>
          <div className="EnrollmentTerms__list">{this.termNames()}</div>
        </div>
        {this.renderSetBody()}
      </div>
    )
  }
}
