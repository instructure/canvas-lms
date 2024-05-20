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

import _ from 'lodash'
import $ from 'jquery'
import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import {Simulate, findRenderedDOMComponentWithTag} from 'react-dom/test-utils'
import gradingPeriodSetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import enrollmentTermsApi from 'ui/features/account_grading_standards/enrollmentTermsApi'
import GradingPeriodSetCollection from 'ui/features/account_grading_standards/react/GradingPeriodSetCollection'

const wrapper = document.getElementById('fixtures')

const assertCollapsed = function (component, setId) {
  const message = `set with id: ${setId} is 'collapsed'`
  equal(component.refs[`show-grading-period-set-${setId}`].props.expanded, false, message)
}

const assertExpanded = function (component, setId) {
  const message = `set with id: ${setId} is 'expanded'`
  equal(component.refs[`show-grading-period-set-${setId}`].props.expanded, true, message)
}

const exampleSet = {
  id: '1',
  displayTotalsForAllGradingPeriods: true,
  title: 'Fall 2015',
  gradingPeriods: [
    {
      id: '1',
      title: 'Q1',
      startDate: new Date('2015-09-01T12:00:00Z'),
      endDate: new Date('2015-10-31T12:00:00Z'),
      closeDate: new Date('2015-10-31T12:00:00Z'),
    },
    {
      id: '2',
      title: 'Q2',
      startDate: new Date('2015-11-01T12:00:00Z'),
      endDate: new Date('2015-12-31T12:00:00Z'),
      closeDate: new Date('2015-12-31T12:00:00Z'),
    },
  ],
  permissions: {read: true, create: true, update: true, delete: true},
  createdAt: new Date('2015-08-27T16:51:41Z'),
}

const exampleSets = [
  exampleSet,
  {
    id: '2',
    displayTotalsForAllGradingPeriods: true,
    title: 'Spring 2016',
    gradingPeriods: [],
    permissions: {read: true, create: true, update: true, delete: true},
    createdAt: new Date('2015-06-27T16:51:41Z'),
  },
]

const exampleTerms = [
  {
    id: '1',
    name: 'Fall 2013 - Art',
    startAt: new Date('2013-06-03T02:57:42Z'),
    endAt: new Date('2013-12-03T02:57:53Z'),
    createdAt: new Date('2015-10-27T16:51:41Z'),
    gradingPeriodGroupId: '2',
    displayName: 'Fall 2013 - Art',
  },
  {
    id: '3',
    name: null,
    startAt: new Date('2014-01-03T02:58:36Z'),
    endAt: new Date('2014-03-03T02:58:42Z'),
    createdAt: new Date('2013-06-02T17:29:19Z'),
    gradingPeriodGroupId: '22',
    displayName: 'Term starting Jan 3, 2014',
  },
  {
    id: '4',
    name: null,
    startAt: null,
    endAt: null,
    createdAt: new Date('2014-05-02T17:29:19Z'),
    gradingPeriodGroupId: '1',
    displayName: 'Term created May 2, 2014',
  },
]

const exampleProps = {
  urls: {
    gradingPeriodSetsURL: 'api/v1/accounts/1/grading_period_sets',
    enrollmentTermsURL: 'api/v1/accounts/1/terms',
    deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D',
    gradingPeriodsUpdateURL: 'api/v1/accounts/1/grading_periods/batch_update',
  },
  readOnly: false,
}

function renderComponent(props = {}) {
  let component
  const element = React.createElement(GradingPeriodSetCollection, {
    ref: ref => {
      component = ref
    },
    ...exampleProps,
    ...props,
  })
  ReactDOM.render(element, wrapper)
  return component
}

QUnit.module('GradingPeriodSetCollection - API Data Load', {
  stubTermsSuccess() {
    const termsSuccess = Promise.resolve(exampleTerms)
    sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
    return termsSuccess
  },

  stubSetsSuccess() {
    const setsSuccess = Promise.resolve(exampleSets)
    sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    return setsSuccess
  },

  stubSetsFailure() {
    const setsFailure = Promise.reject(new Error('FAIL'))
    sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsFailure)
    return setsFailure
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('loads enrollment terms', function () {
  const terms = this.stubTermsSuccess()
  const sets = this.stubSetsSuccess()
  const collection = renderComponent()

  return Promise.all([terms, sets]).then(() => {
    propEqual(_.map(collection.state.enrollmentTerms, 'id'), _.map(exampleTerms, 'id'))
  })
})

test('loads grading period sets', function () {
  const terms = this.stubTermsSuccess()
  const sets = this.stubSetsSuccess()
  const collection = renderComponent()

  return Promise.all([terms, sets]).then(() => {
    propEqual(_.map(collection.state.sets, 'id'), _.map(exampleSets, 'id'))
  })
})

test('has an empty set collection if sets failed to load', function () {
  const terms = this.stubTermsSuccess()
  const sets = this.stubSetsFailure()
  const collection = renderComponent()

  return Promise.all([terms, sets]).catch(() => {
    propEqual(collection.state.sets, [])
  })
})

QUnit.module('GradingPeriodSetCollection', {
  setup() {
    const setsSuccess = new Promise(resolve => resolve(exampleSets))
    const termsSuccess = new Promise(resolve => resolve(exampleTerms))
    this.sets = sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    this.terms = sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('uses the name, start date (if no name), or creation date (if no start) for the display name', function () {
  const collection = renderComponent()
  const expectedNames = ['Fall 2013 - Art', 'Term starting Jan 3, 2014', 'Term created May 2, 2014']

  return Promise.all([this.terms, this.sets]).then(() => {
    const actualNames = _.map(collection.state.enrollmentTerms, 'displayName')
    propEqual(expectedNames, actualNames)
  })
})

test('initially renders each set as "collapsed"', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    assertCollapsed(collection, '1')
    assertCollapsed(collection, '2')
  })
})

test('each set "onToggleBody" property will toggle its "expanded" state', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    collection.refs['show-grading-period-set-1'].props.onToggleBody()
    assertExpanded(collection, '1')
    assertCollapsed(collection, '2')
    collection.refs['show-grading-period-set-2'].props.onToggleBody()
    assertExpanded(collection, '1')
    assertExpanded(collection, '2')
    collection.refs['show-grading-period-set-1'].props.onToggleBody()
    assertCollapsed(collection, '1')
    assertExpanded(collection, '2')
  })
})

test('does not show the new set form on initial load', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    notOk(collection.refs.newSetForm)
  })
})

test('has the add new set button enabled on initial load', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const component = collection.refs.addSetFormButton
    const button = findRenderedDOMComponentWithTag(component, 'button')
    notEqual(button.getAttribute('aria-disabled'), 'true')
  })
})

test('disables the add new set button after it is clicked', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const component = collection.refs.addSetFormButton
    const button = findRenderedDOMComponentWithTag(component, 'button')
    Simulate.click(button)
    strictEqual(button.getAttribute('disabled'), '')
  })
})

test('shows the new set form when the add new set button is clicked', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const component = collection.refs.addSetFormButton
    const button = findRenderedDOMComponentWithTag(component, 'button')
    Simulate.click(button)
    ok(collection.refs.newSetForm)
  })
})

test('closes the new set form when closeNewSetForm is called', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    collection.closeNewSetForm()
    notOk(collection.refs.newSetForm)
  })
})

test('termsBelongingToActiveSets only includes terms that belong to active (non-deleted) sets', function () {
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    const expectedTerms = _.map(exampleTerms, term => term)
    expectedTerms.splice(1, 1)
    expectedTerms.splice(2, 1)
    propEqual(collection.termsBelongingToActiveSets(), expectedTerms)
  })
})

test('termsNotBelongingToActiveSets only includes terms that do not belong to active (non-deleted) sets', function () {
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    const expectedTerms = _.map(exampleTerms, term => term)
    expectedTerms.splice(0, 1)
    expectedTerms.splice(1, 1)
    propEqual(collection.termsNotBelongingToActiveSets(), expectedTerms)
  })
})

QUnit.module('GradingPeriodSetCollection - Search', {
  setup() {
    const setsSuccess = new Promise(resolve => resolve(exampleSets))
    const termsSuccess = new Promise(resolve => resolve(exampleTerms))
    this.sets = sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    this.terms = sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('setAndGradingPeriodTitles returns an array of set and grading period title names', function () {
  const set = {
    title: 'Set!',
    gradingPeriods: [{title: 'Grading Period 1'}, {title: 'Grading Period 2'}],
  }
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const titles = collection.setAndGradingPeriodTitles(set)
    propEqual(titles, ['Set!', 'Grading Period 1', 'Grading Period 2'])
  })
})

test('setAndGradingPeriodTitles filters out empty, null, and undefined titles', function () {
  const set = {
    title: null,
    gradingPeriods: [{title: 'Grading Period 1'}, {}, {title: 'Grading Period 2'}, {title: ''}],
  }

  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const titles = collection.setAndGradingPeriodTitles(set)
    propEqual(titles, ['Grading Period 1', 'Grading Period 2'])
  })
})

test('changeSearchText calls setState if the new search text differs from the old search text', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const setStateSpy = sandbox.spy(collection, 'setState')
    collection.changeSearchText('hello world')
    collection.changeSearchText('goodbye world')
    ok(setStateSpy.calledTwice)
  })
})

test('changeSearchText does not call setState if the new search text equals the old search text', function () {
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const setStateSpy = sandbox.spy(collection, 'setState')
    collection.changeSearchText('hello world')
    collection.changeSearchText('hello world')
    ok(setStateSpy.calledOnce)
  })
})

test('searchTextMatchesTitles returns true if the search text exactly matches one of the titles', function () {
  const titles = ['hello world', 'goodbye friend']
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    collection.changeSearchText('hello world')
    equal(collection.searchTextMatchesTitles(titles), true)
  })
})

test('searchTextMatchesTitles returns true if the search text is a substring of one of the titles', function () {
  const titles = ['hello world', 'goodbye friend']
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    collection.changeSearchText('orl')
    equal(collection.searchTextMatchesTitles(titles), true)
  })
})

test('searchTextMatchesTitles returns false if the search text is a not a substring of any of the titles', function () {
  const titles = ['hello world', 'goodbye friend']
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    collection.changeSearchText('olr')
    equal(collection.searchTextMatchesTitles(titles), false)
  })
})

test('getVisibleSets returns sets that match the search text', function () {
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    collection.changeSearchText('201')
    let filteredIDs = _.map(collection.getVisibleSets(), 'id')
    propEqual(filteredIDs, ['1', '2'])

    collection.changeSearchText('pring')
    filteredIDs = _.map(collection.getVisibleSets(), 'id')
    propEqual(filteredIDs, ['2'])

    collection.changeSearchText('Fal')
    filteredIDs = _.map(collection.getVisibleSets(), 'id')
    propEqual(filteredIDs, ['1'])

    collection.changeSearchText('does not match')
    filteredIDs = _.map(collection.getVisibleSets(), 'id')
    propEqual(collection.getVisibleSets(), [])
  })
})

test('announces number of search results for screen readers', function () {
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    const flashStub = sandbox.spy($, 'screenReaderFlashMessageExclusive')
    collection.changeSearchText('201')
    const message = '2 sets of grading periods found.'
    deepEqual(flashStub.firstCall.args, [message, true])

    collection.changeSearchText('')
    deepEqual(flashStub.secondCall.args, ['Showing all sets of grading periods.', true])
  })
})

test('preserves the "expanded" state of each set', function () {
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    collection.refs['show-grading-period-set-1'].props.onToggleBody()

    collection.changeSearchText('201')
    assertExpanded(collection, '1')
    assertCollapsed(collection, '2')

    // clear all sets from search results
    collection.changeSearchText('does not match')

    collection.changeSearchText('201')
    assertExpanded(collection, '1')
    assertCollapsed(collection, '2')
  })
})

test('deserializes enrollment terms if the AJAX call is successful', function () {
  const deserializedTerm = exampleTerms[0]
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    const term = collection.state.enrollmentTerms[0]
    propEqual(term, deserializedTerm)
  })
})

test('uses the name, start date (if no name), or creation date (if no start) for the display name', function () {
  const expectedNames = _.map(exampleTerms, 'displayName')
  const collection = renderComponent()

  return Promise.all([this.terms, this.sets]).then(() => {
    const names = _.map(collection.state.enrollmentTerms, 'displayName')
    propEqual(names, expectedNames)
  })
})

test('filterSetsBySelectedTerm returns all the sets if "All Terms" is selected', function () {
  const ALL_TERMS_ID = '0'
  const selectedTermID = ALL_TERMS_ID
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    const filteredSets = collection.filterSetsBySelectedTerm(
      exampleSets,
      exampleTerms,
      selectedTermID
    )
    propEqual(filteredSets, exampleSets)
  })
})

test('filterSetsBySelectedTerm filters to only show the set that the selected term belongs to', function () {
  let selectedTermID = '1'
  const collection = renderComponent()
  return Promise.all([this.terms, this.sets]).then(() => {
    let filteredSets = collection.filterSetsBySelectedTerm(
      exampleSets,
      exampleTerms,
      selectedTermID
    )
    let expectedSets = _.filter(exampleSets, {id: '2'})
    propEqual(filteredSets, expectedSets)

    selectedTermID = '4'
    filteredSets = collection.filterSetsBySelectedTerm(exampleSets, exampleTerms, selectedTermID)
    expectedSets = _.filter(exampleSets, {id: '1'})
    propEqual(filteredSets, expectedSets)
  })
})

QUnit.module('GradingPeriodSetCollection - Add Set', {
  setup() {
    const setsSuccess = new Promise(resolve => resolve([]))
    const termsSuccess = new Promise(resolve => resolve(exampleTerms))
    this.sets = sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    this.terms = sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('addGradingPeriodSet adds the set to the collection', function () {
  const collection = renderComponent()

  return Promise.all([this.sets, this.terms]).then(() => {
    collection.addGradingPeriodSet(exampleSet)
    ok(collection.refs['show-grading-period-set-1'], 'the grading period set is visible')
    const setIDs = _.map(collection.state.sets, 'id')
    propEqual(setIDs, ['1'])
  })
})

test('addGradingPeriodSet renders the new set expanded', function () {
  const collection = renderComponent()

  return Promise.all([this.sets, this.terms]).then(() => {
    collection.addGradingPeriodSet(exampleSet)
    assertExpanded(collection, '1')
  })
})

QUnit.module('GradingPeriodSetCollection - Delete Set', {
  setup() {
    const setsSuccess = new Promise(resolve => resolve(exampleSets))
    const termsSuccess = new Promise(resolve => resolve(exampleTerms))
    this.sets = sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    this.terms = sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('removeGradingPeriodSet removes the set from the collection', function () {
  const collection = renderComponent()

  return Promise.all([this.sets, this.terms]).then(() => {
    collection.removeGradingPeriodSet('1')
    const setIDs = _.map(collection.state.sets, 'id')
    propEqual(setIDs, ['2'])
  })
})

test('removeGradingPeriodSet focuses on the set above the one deleted, if one exists', function () {
  const collection = renderComponent()

  return Promise.all([this.sets, this.terms]).then(() => {
    collection.removeGradingPeriodSet('2')
    const remainingSet = collection.state.sets[0]
    const gradingPeriodSetRef = collection.getShowGradingPeriodSetRef(remainingSet)
    const gradingPeriodSetComponent = collection.refs[gradingPeriodSetRef]
    strictEqual(gradingPeriodSetComponent._refs.editButton, document.activeElement)
  })
})

test(
  'removeGradingPeriodSet focuses on the "+ Set of Grading Periods" button' +
    ' after deletion if there are no sets above the one that was deleted',
  function () {
    const collection = renderComponent()

    return Promise.all([this.sets, this.terms]).then(() => {
      collection.removeGradingPeriodSet('1')
      const activeElementText = document.activeElement.textContent
      ok(activeElementText.includes('Set of Grading Periods'))
    })
  }
)

QUnit.module('GradingPeriodSetCollection - Update Set Periods', {
  setup() {
    const setsSuccess = new Promise(resolve => resolve(exampleSets))
    const termsSuccess = new Promise(resolve => resolve(exampleTerms))
    this.sets = sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    this.terms = sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('updateSetPeriods updates the grading periods on the given set', function () {
  const collection = renderComponent()

  return Promise.all([this.sets, this.terms]).then(() => {
    collection.updateSetPeriods('1', [])
    const set = _.find(collection.state.sets, {id: '1'})
    propEqual(set.gradingPeriods, [])
  })
})

QUnit.module('GradingPeriodSetCollection "Edit Grading Period Set"', {
  setup() {
    const setsSuccess = new Promise(resolve => resolve(exampleSets))
    const termsSuccess = new Promise(resolve => resolve(exampleTerms))
    this.sets = sandbox.stub(gradingPeriodSetsApi, 'list').returns(setsSuccess)
    this.terms = sandbox.stub(enrollmentTermsApi, 'list').returns(termsSuccess)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('renders the "edit grading period set" when "edit grading period set" is clicked', function () {
  const set = renderComponent()
  return Promise.all([this.sets, this.terms]).then(() => {
    notOk(
      !!set.refs['edit-grading-period-set-1'],
      'the edit grading period set form is not visible'
    )
    const {editButton} = set.refs['show-grading-period-set-1']._refs
    Simulate.click(editButton)
    ok(set.refs['edit-grading-period-set-1'], 'the edit form is visible')
  })
})

test('disables other "grading period set" actions while open', function () {
  const set = renderComponent()
  return Promise.all([this.sets, this.terms]).then(() => {
    const {editButton} = set.refs['show-grading-period-set-1']._refs
    Simulate.click(editButton)
    notEqual(editButton.getAttribute('aria-disabled'), 'true')
    ok(set.refs['show-grading-period-set-2'].props.actionsDisabled)
  })
})

test('"onCancel" removes the "edit grading period set" form', function () {
  const set = renderComponent()
  return Promise.all([this.sets, this.terms]).then(() => {
    const {editButton} = set.refs['show-grading-period-set-1']._refs
    Simulate.click(editButton)
    set.refs['edit-grading-period-set-1'].props.onCancel()
    notOk(!!set.refs['edit-grading-period-set-1'])
  })
})

test('"onCancel" focuses on the "edit grading period set" button', function () {
  const set = renderComponent()
  return Promise.all([this.sets, this.terms]).then(() => {
    const {editButton} = set.refs['show-grading-period-set-1']._refs
    Simulate.click(editButton)
    set.refs['edit-grading-period-set-1'].props.onCancel()
    equal(document.activeElement.innerText, `Edit ${exampleSets[0].title}`)
  })
})

test('"onCancel" re-enables all grading period set actions', function () {
  const set = renderComponent()
  return Promise.all([this.sets, this.terms]).then(() => {
    const {editButton} = set.refs['show-grading-period-set-1']._refs
    Simulate.click(editButton)
    set.refs['edit-grading-period-set-1'].props.onCancel()
    notEqual(editButton.getAttribute('aria-disabled'), 'true')
    notOk(set.refs['show-grading-period-set-2'].props.actionsDisabled)
  })
})

QUnit.module('GradingPeriodSetCollection "Edit Grading Period Set - onSave"', {
  setup() {
    sandbox.stub(gradingPeriodSetsApi, 'list').returns(new Promise(() => {}))
    sandbox.stub(enrollmentTermsApi, 'list').returns(new Promise(() => {}))
  },

  renderComponent() {
    const component = renderComponent()
    component.onTermsLoaded(exampleTerms)
    component.onSetsLoaded(exampleSets)
    const {editButton} = component.refs['show-grading-period-set-1']._refs
    Simulate.click(editButton)
    return component
  },

  callOnSave(collection) {
    const {saveButton} = collection.refs['edit-grading-period-set-1'].refs
    const button = findRenderedDOMComponentWithTag(saveButton, 'button')
    Simulate.click(button)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('removes the "edit grading period set" form', function () {
  const updatedSet = {...exampleSet, title: 'Updated Title'}
  const success = Promise.resolve(updatedSet)
  sandbox.stub(gradingPeriodSetsApi, 'update').returns(success)
  const collection = this.renderComponent()
  this.callOnSave(collection)
  return success.then(() => {
    ok(collection.refs['show-grading-period-set-1'])
    notOk(!!collection.refs['edit-grading-period-set-1'])
  })
})

test('updates the given grading period set', function () {
  const updatedSet = {...exampleSet, title: 'Updated Title'}
  const success = Promise.resolve(updatedSet)
  sandbox.stub(gradingPeriodSetsApi, 'update').returns(success)
  const collection = this.renderComponent()
  this.callOnSave(collection)
  return success.then(() => {
    const setComponent = collection.refs['show-grading-period-set-1']
    equal(setComponent.props.set.title, 'Updated Title')
  })
})

test('re-enables all grading period set actions', function () {
  const updatedSet = {...exampleSet, title: 'Updated Title'}
  const success = Promise.resolve(updatedSet)
  sandbox.stub(gradingPeriodSetsApi, 'update').returns(success)
  const collection = this.renderComponent()
  this.callOnSave(collection)
  return success.then(() => {
    const component = collection.refs.addSetFormButton
    const button = findRenderedDOMComponentWithTag(component, 'button')
    notEqual(button.getAttribute('aria-disabled'), 'true')
    notOk(collection.refs['show-grading-period-set-1'].props.actionsDisabled)
    notOk(collection.refs['show-grading-period-set-2'].props.actionsDisabled)
  })
})

test('preserves the "edit grading period set" form upon failure', function () {
  const failure = Promise.reject(new Error('FAIL'))
  sandbox.stub(gradingPeriodSetsApi, 'update').returns(failure)
  const collection = this.renderComponent()
  this.callOnSave(collection)
  return failure.catch(() => {
    ok(collection.refs['edit-grading-period-set-1'])
    notOk(!!collection.refs['show-grading-period-set-1'])
  })
})
