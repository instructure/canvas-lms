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
import PropTypes from 'prop-types'
import {
  compact,
  difference,
  filter,
  find,
  includes,
  isDate,
  map,
  reject,
  some,
  sortBy,
  union,
  without,
} from 'lodash'
import $ from 'jquery'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import GradingPeriodSet from './GradingPeriodSet'
import SearchGradingPeriodsField from './SearchGradingPeriodsField'
import SearchHelpers from '@canvas/util/searchHelpers'
import DateHelper from '@canvas/datetime/dateHelper'
import EnrollmentTermsDropdown from './EnrollmentTermsDropdown'
import NewGradingPeriodSetForm from './NewGradingPeriodSetForm'
import EditGradingPeriodSetForm from './EditGradingPeriodSetForm'
import SetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import TermsApi from './enrollmentTermsApi'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('GradingPeriodSetCollection')

const presentEnrollmentTerms = function (enrollmentTerms) {
  return map(enrollmentTerms, term => {
    const newTerm = {...term}

    if (newTerm.name) {
      newTerm.displayName = newTerm.name
    } else if (isDate(newTerm.startAt)) {
      const started = DateHelper.formatDateForDisplay(newTerm.startAt)
      newTerm.displayName = I18n.t('Term starting ') + started
    } else {
      const created = DateHelper.formatDateForDisplay(newTerm.createdAt)
      newTerm.displayName = I18n.t('Term created ') + created
    }

    return newTerm
  })
}

const getEditGradingPeriodSetRef = function (set) {
  return `edit-grading-period-set-${set.id}`
}

const {bool, string, shape} = PropTypes

export default class GradingPeriodSetCollection extends React.Component {
  static propTypes = {
    readOnly: bool.isRequired,

    urls: shape({
      gradingPeriodSetsURL: string.isRequired,
      gradingPeriodsUpdateURL: string.isRequired,
      enrollmentTermsURL: string.isRequired,
      deleteGradingPeriodURL: string.isRequired,
    }).isRequired,
  }

  state = {
    enrollmentTerms: [],
    sets: [],
    expandedSetIDs: [],
    showNewSetForm: false,
    searchText: '',
    selectedTermID: '0',
    editSet: {
      id: null,
      saving: false,
    },
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.editSet.id && prevState.editSet.id !== this.state.editSet.id) {
      const set = {id: prevState.editSet.id}
      this.refs[this.getShowGradingPeriodSetRef(set)]._refs.editButton.focus()
    }
  }

  addGradingPeriodSet = (set, termIDs) => {
    this.setState(
      {
        sets: [set].concat(this.state.sets),
        expandedSetIDs: this.state.expandedSetIDs.concat([set.id]),
        enrollmentTerms: this.associateTermsWithSet(set.id, termIDs),
        showNewSetForm: false,
      },
      () => {
        this.refs.addSetFormButton.focus()
      }
    )
  }

  associateTermsWithSet = (setID, termIDs) =>
    map(this.state.enrollmentTerms, term => {
      if (includes(termIDs, term.id)) {
        const newTerm = {...term}
        newTerm.gradingPeriodGroupId = setID
        return newTerm
      } else {
        return term
      }
    })

  UNSAFE_componentWillMount() {
    this.getSets()
    this.getTerms()
  }

  getSets = () => {
    SetsApi.list()
      .then(sets => {
        this.onSetsLoaded(sets)
      })
      .catch(_ => {
        $.flashError(I18n.t('An error occured while fetching grading period sets.'))
      })
  }

  getTerms = () => {
    TermsApi.list()
      .then(terms => {
        this.onTermsLoaded(terms)
      })
      .catch(_ => {
        $.flashError(I18n.t('An error occured while fetching enrollment terms.'))
      })
  }

  onTermsLoaded = terms => {
    this.setState({enrollmentTerms: presentEnrollmentTerms(terms)})
  }

  onSetsLoaded = sets => {
    const sortedSets = sortBy(sets, 'createdAt').reverse()
    this.setState({sets: sortedSets})
  }

  onSetUpdated = updatedSet => {
    const sets = map(this.state.sets, set =>
      set.id === updatedSet.id ? {...set, ...updatedSet} : set
    )

    const terms = map(this.state.enrollmentTerms, term => {
      if (includes(updatedSet.enrollmentTermIDs, term.id)) {
        return {...term, gradingPeriodGroupId: updatedSet.id}
      } else if (term.gradingPeriodGroupId === updatedSet.id) {
        return {...term, gradingPeriodGroupId: null}
      } else {
        return term
      }
    })

    this.setState({sets, enrollmentTerms: terms})
    $.flashMessage(I18n.t('The grading period set was updated successfully.'))
  }

  setAndGradingPeriodTitles = set => {
    const titles = map(set.gradingPeriods, 'title')
    titles.unshift(set.title)
    return compact(titles)
  }

  searchTextMatchesTitles = titles =>
    some(titles, title => SearchHelpers.substringMatchRegex(this.state.searchText).test(title))

  filterSetsBySearchText = (sets, searchText) => {
    if (searchText === '') return sets

    return filter(sets, set => {
      const titles = this.setAndGradingPeriodTitles(set)
      return this.searchTextMatchesTitles(titles)
    })
  }

  changeSearchText = searchText => {
    if (searchText !== this.state.searchText) {
      this.setState({searchText})
    }
  }

  filterSetsBySelectedTerm = (sets, terms, selectedTermID) => {
    if (selectedTermID === '0') return sets

    const activeTerm = find(terms, {id: selectedTermID})
    const setID = activeTerm.gradingPeriodGroupId
    return filter(sets, {id: setID})
  }

  changeSelectedEnrollmentTerm = event => {
    this.setState({selectedTermID: event.target.value})
  }

  alertForMatchingSets = numSets => {
    let msg
    if (this.state.selectedTermID === '0' && this.state.searchText === '') {
      msg = I18n.t('Showing all sets of grading periods.')
    } else {
      msg = I18n.t(
        {
          one: '1 set of grading periods found.',
          other: '%{count} sets of grading periods found.',
          zero: 'No matching sets of grading periods found.',
        },
        {count: numSets}
      )
    }
    const polite = true
    $.screenReaderFlashMessageExclusive(msg, polite)
  }

  getVisibleSets = () => {
    const setsFilteredBySearchText = this.filterSetsBySearchText(
      this.state.sets,
      this.state.searchText
    )
    const filterByTermArgs = [
      setsFilteredBySearchText,
      this.state.enrollmentTerms,
      this.state.selectedTermID,
    ]
    const visibleSets = this.filterSetsBySelectedTerm(...filterByTermArgs)
    this.alertForMatchingSets(visibleSets.length)
    return visibleSets
  }

  toggleSetBody = setId => {
    if (includes(this.state.expandedSetIDs, setId)) {
      this.setState({expandedSetIDs: without(this.state.expandedSetIDs, setId)})
    } else {
      this.setState({expandedSetIDs: this.state.expandedSetIDs.concat([setId])})
    }
  }

  editGradingPeriodSet = set => {
    this.setState({editSet: {id: set.id, saving: false}})
  }

  nodeToFocusOnAfterSetDeletion = setID => {
    const index = this.state.sets.findIndex(set => set.id === setID)
    if (index < 1) {
      return this.refs.addSetFormButton
    } else {
      const setRef = this.getShowGradingPeriodSetRef(this.state.sets[index - 1])
      const setToFocus = this.refs[setRef]
      return setToFocus._refs.editButton
    }
  }

  removeGradingPeriodSet = setID => {
    const newSets = reject(this.state.sets, set => set.id === setID)
    const nodeToFocus = this.nodeToFocusOnAfterSetDeletion(setID)
    this.setState({sets: newSets}, () => nodeToFocus.focus())
  }

  updateSetPeriods = (setID, gradingPeriods) => {
    const newSets = map(this.state.sets, set => {
      if (set.id === setID) {
        return {...set, gradingPeriods}
      }

      return set
    })

    this.setState({sets: newSets})
  }

  openNewSetForm = () => {
    this.setState({showNewSetForm: true})
  }

  closeNewSetForm = () => {
    this.setState({showNewSetForm: false}, () => {
      this.refs.addSetFormButton.focus()
    })
  }

  termsBelongingToActiveSets = () => {
    const setIDs = map(this.state.sets, 'id')
    return filter(this.state.enrollmentTerms, term => {
      const setID = term.gradingPeriodGroupId
      return setID && includes(setIDs, setID)
    })
  }

  termsNotBelongingToActiveSets = () =>
    difference(this.state.enrollmentTerms, this.termsBelongingToActiveSets())

  selectableTermsForEditSetForm = setID => {
    const termsBelongingToThisSet = filter(this.termsBelongingToActiveSets(), {
      gradingPeriodGroupId: setID,
    })
    return union(this.termsNotBelongingToActiveSets(), termsBelongingToThisSet)
  }

  closeEditSetForm = _id => {
    this.setState({editSet: {id: null, saving: false}})
  }

  getShowGradingPeriodSetRef = set => `show-grading-period-set-${set.id}`

  renderEditGradingPeriodSetForm = set => {
    const cancelCallback = () => {
      this.closeEditSetForm(set.id)
    }

    const saveCallback = set => {
      const editSet = {...this.state.editSet, saving: true}
      this.setState({editSet})
      SetsApi.update(set)
        .then(updated => {
          this.onSetUpdated(updated)
          this.closeEditSetForm(set.id)
        })
        .catch(_ => {
          $.flashError(I18n.t('An error occured while updating the grading period set.'))
        })
    }

    return (
      <EditGradingPeriodSetForm
        key={set.id}
        ref={getEditGradingPeriodSetRef(set)}
        set={set}
        enrollmentTerms={this.selectableTermsForEditSetForm(set.id)}
        disabled={this.state.editSet.saving}
        onCancel={cancelCallback}
        onSave={saveCallback}
      />
    )
  }

  renderSets() {
    const urls = {
      batchUpdateURL: this.props.urls.gradingPeriodsUpdateURL,
      gradingPeriodSetsURL: this.props.urls.gradingPeriodSetsURL,
      deleteGradingPeriodURL: this.props.urls.deleteGradingPeriodURL,
    }

    return map(this.getVisibleSets(), set => {
      if (this.state.editSet.id === set.id) {
        return this.renderEditGradingPeriodSetForm(set)
      } else {
        return (
          <GradingPeriodSet
            key={set.id}
            ref={this.getShowGradingPeriodSetRef(set)}
            set={set}
            gradingPeriods={set.gradingPeriods}
            urls={urls}
            actionsDisabled={!!this.state.editSet.id}
            readOnly={this.props.readOnly}
            permissions={set.permissions}
            terms={this.state.enrollmentTerms}
            expanded={includes(this.state.expandedSetIDs, set.id)}
            onEdit={this.editGradingPeriodSet}
            onDelete={this.removeGradingPeriodSet}
            onPeriodsChange={this.updateSetPeriods}
            onToggleBody={() => {
              this.toggleSetBody(set.id)
            }}
          />
        )
      }
    })
  }

  renderNewGradingPeriodSetForm = () => {
    if (this.state.showNewSetForm) {
      return (
        <NewGradingPeriodSetForm
          ref="newSetForm"
          closeForm={this.closeNewSetForm}
          urls={this.props.urls}
          enrollmentTerms={this.termsNotBelongingToActiveSets()}
          addGradingPeriodSet={this.addGradingPeriodSet}
        />
      )
    }
  }

  renderAddSetFormButton = () => {
    const disable = this.state.showNewSetForm || !!this.state.editSet.id
    if (!this.props.readOnly) {
      return (
        <Button
          ref="addSetFormButton"
          color="primary"
          disabled={disable}
          onClick={this.openNewSetForm}
          aria-label={I18n.t('Add Set of Grading Periods')}
        >
          <i className="icon-plus" />
          &nbsp;
          <span aria-hidden="true">{I18n.t('Set of Grading Periods')}</span>
        </Button>
      )
    }
  }

  render() {
    return (
      <div>
        <div className="GradingPeriodSets__toolbar header-bar no-line ic-Form-action-box">
          <div className="ic-Form-action-box__Form">
            <div className="ic-Form-control">
              <EnrollmentTermsDropdown
                terms={this.termsBelongingToActiveSets()}
                changeSelectedEnrollmentTerm={this.changeSelectedEnrollmentTerm}
              />
            </div>

            <SearchGradingPeriodsField changeSearchText={this.changeSearchText} />
            <div className="ic-Form-action-box__Actions">{this.renderAddSetFormButton()}</div>
          </div>
        </div>

        {this.renderNewGradingPeriodSetForm()}
        <div id="grading-period-sets">{this.renderSets()}</div>
      </div>
    )
  }
}
