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

import React, {useCallback, useEffect, useRef} from 'react'
import {
  compact,
  difference,
  filter,
  find,
  includes,
  isDate,
  reject,
  some,
  union,
  without,
} from 'es-toolkit/compat'
import $ from 'jquery'
import {Button} from '@instructure/ui-buttons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import GradingPeriodSet from './GradingPeriodSet'
import SearchGradingPeriodsField from './SearchGradingPeriodsField'
import SearchHelpers from '@canvas/util/searchHelpers'
import DateHelper from '@canvas/datetime/dateHelper'
import EnrollmentTermsDropdown from './EnrollmentTermsDropdown'
import NewGradingPeriodSetForm from './NewGradingPeriodSetForm'
import EditGradingPeriodSetForm from './EditGradingPeriodSetForm'
import SetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import type {GradingPeriodSetUpdateParams} from '@canvas/grading/jquery/gradingPeriodSetsApi'
import type {CamelizedGradingPeriodSet} from '@canvas/grading/grading.d'
import TermsApi from '../enrollmentTermsApi'
import type {EnrollmentTerm as ApiEnrollmentTerm} from '../enrollmentTermsApi'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import {useSetState} from 'react-use'
import type {
  CollectionUrls,
  EnrollmentTerm,
  GradingPeriodSet as GradingPeriodSetData,
  Permissions,
} from './types'

const I18n = createI18nScope('GradingPeriodSetCollection')

const normalizePermissions = (value: unknown): Permissions => {
  const source =
    typeof value === 'object' && value !== null ? (value as Record<string, unknown>) : {}

  return {
    read: !!source.read,
    create: !!source.create,
    update: !!source.update,
    delete: !!source.delete,
  }
}

const normalizeSet = (set: CamelizedGradingPeriodSet): GradingPeriodSetData => ({
  ...set,
  permissions: normalizePermissions(set.permissions),
})

const presentEnrollmentTerms = function (enrollmentTerms: EnrollmentTerm[]): EnrollmentTerm[] {
  return enrollmentTerms.map(term => {
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

const getEditGradingPeriodSetRef = function (set: GradingPeriodSetData): string {
  return `edit-grading-period-set-${set.id}`
}

interface GradingPeriodSetCollectionProps {
  readOnly: boolean
  urls: CollectionUrls
}

interface EditSetState {
  id: string | null
  saving: boolean
}

interface CollectionState {
  enrollmentTerms: EnrollmentTerm[]
  sets: GradingPeriodSetData[]
  expandedSetIDs: string[]
  showNewSetForm: boolean
  searchText: string
  selectedTermID: string
  editSet: EditSetState
}

const GradingPeriodSetCollection = ({readOnly, urls}: GradingPeriodSetCollectionProps) => {
  const [state, setState] = useSetState<CollectionState>({
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
  })

  const addSetFormButtonRef = useRef<HTMLButtonElement | null>(null)
  const setRefs = useRef<Record<string, unknown>>({})

  // TODO: use TanStack Query
  useEffect(() => {
    getSets()
    getTerms()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const onTermsLoaded = useCallback(
    (terms: EnrollmentTerm[]) => {
      setState({enrollmentTerms: presentEnrollmentTerms(terms)})
    },
    [setState],
  )

  const onSetsLoaded = useCallback(
    (sets: CamelizedGradingPeriodSet[]) => {
      const sortedSets = sets
        .map(normalizeSet)
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      setState({sets: sortedSets})
    },
    [setState],
  )

  const getSets = useCallback(() => {
    SetsApi.list()
      .then((sets: CamelizedGradingPeriodSet[]) => {
        onSetsLoaded(sets)
      })
      .catch(_ => {
        $.flashError(I18n.t('An error occured while fetching grading period sets.'))
      })
  }, [onSetsLoaded])

  const getTerms = useCallback(() => {
    TermsApi.list()
      .then((terms: ApiEnrollmentTerm[]) => {
        onTermsLoaded(terms)
      })
      .catch(_ => {
        $.flashError(I18n.t('An error occured while fetching enrollment terms.'))
      })
  }, [onTermsLoaded])

  const associateTermsWithSet = useCallback(
    (setID: string, termIDs: string[]) =>
      state.enrollmentTerms.map(term => {
        if (includes(termIDs, term.id)) {
          return {...term, gradingPeriodGroupId: setID}
        }

        return term
      }),
    [state.enrollmentTerms],
  )

  const addGradingPeriodSet = useCallback(
    (set: GradingPeriodSetData, termIDs: string[]) => {
      setState({
        sets: [set].concat(state.sets),
        expandedSetIDs: state.expandedSetIDs.concat([set.id]),
        enrollmentTerms: associateTermsWithSet(set.id, termIDs),
        showNewSetForm: false,
      })

      requestAnimationFrame(() => {
        addSetFormButtonRef.current?.focus()
      })
    },
    [state.sets, state.expandedSetIDs, setState, associateTermsWithSet],
  )

  const onSetUpdated = useCallback(
    (updatedSet: GradingPeriodSetData) => {
      const sets = state.sets.map(set => (set.id === updatedSet.id ? {...set, ...updatedSet} : set))

      const terms = state.enrollmentTerms.map(term => {
        if (includes(updatedSet.enrollmentTermIDs ?? [], term.id)) {
          return {...term, gradingPeriodGroupId: updatedSet.id}
        }

        if (term.gradingPeriodGroupId === updatedSet.id) {
          return {...term, gradingPeriodGroupId: null}
        }

        return term
      })

      setState({sets, enrollmentTerms: terms})
      $.flashMessage(I18n.t('The grading period set was updated successfully.'))
    },
    [state.sets, state.enrollmentTerms, setState],
  )

  const setAndGradingPeriodTitles = useCallback((set: GradingPeriodSetData) => {
    const titles = set.gradingPeriods.map(period => period.title)
    titles.unshift(set.title)
    return compact(titles)
  }, [])

  const searchTextMatchesTitles = useCallback(
    (titles: string[]) =>
      some(titles, title => SearchHelpers.substringMatchRegex(state.searchText).test(title)),
    [state.searchText],
  )

  const filterSetsBySearchText = useCallback(
    (sets: GradingPeriodSetData[], searchText: string) => {
      if (searchText === '') return sets

      return filter(sets, set => {
        const titles = setAndGradingPeriodTitles(set)
        return searchTextMatchesTitles(titles)
      })
    },
    [setAndGradingPeriodTitles, searchTextMatchesTitles],
  )

  const changeSearchText = useCallback(
    (searchText: string) => {
      if (searchText !== state.searchText) {
        setState({searchText})
      }
    },
    [state.searchText, setState],
  )

  const filterSetsBySelectedTerm = useCallback(
    (sets: GradingPeriodSetData[], terms: EnrollmentTerm[], selectedTermID: string) => {
      if (selectedTermID === '0') return sets

      const activeTerm = find(terms, {id: selectedTermID}) as EnrollmentTerm | undefined
      if (!activeTerm?.gradingPeriodGroupId) return []

      return filter(sets, {id: activeTerm.gradingPeriodGroupId})
    },
    [],
  )

  const changeSelectedEnrollmentTerm = useCallback(
    (event: React.ChangeEvent<HTMLSelectElement>) => {
      setState({selectedTermID: event.target.value})
    },
    [setState],
  )

  const alertForMatchingSets = useCallback(
    (numSets: number) => {
      let msg
      if (state.selectedTermID === '0' && state.searchText === '') {
        msg = I18n.t('Showing all sets of grading periods.')
      } else {
        msg = I18n.t(
          {
            one: '1 set of grading periods found.',
            other: '%{count} sets of grading periods found.',
            zero: 'No matching sets of grading periods found.',
          },
          {count: numSets},
        )
      }
      const polite = true
      $.screenReaderFlashMessageExclusive(msg, polite)
    },
    [state.selectedTermID, state.searchText],
  )

  const getVisibleSets = useCallback(() => {
    const setsFilteredBySearchText = filterSetsBySearchText(state.sets, state.searchText)
    const visibleSets = filterSetsBySelectedTerm(
      setsFilteredBySearchText,
      state.enrollmentTerms,
      state.selectedTermID,
    )
    alertForMatchingSets(visibleSets.length)
    return visibleSets
  }, [
    state.sets,
    state.searchText,
    state.enrollmentTerms,
    state.selectedTermID,
    filterSetsBySearchText,
    filterSetsBySelectedTerm,
    alertForMatchingSets,
  ])

  const toggleSetBody = useCallback(
    (setId: string) => {
      if (includes(state.expandedSetIDs, setId)) {
        setState({expandedSetIDs: without(state.expandedSetIDs, setId)})
      } else {
        setState({expandedSetIDs: state.expandedSetIDs.concat([setId])})
      }
    },
    [state.expandedSetIDs, setState],
  )

  const editGradingPeriodSet = useCallback(
    (set: GradingPeriodSetData) => {
      setState({editSet: {id: set.id, saving: false}})
    },
    [setState],
  )

  const nodeToFocusOnAfterSetDeletion = useCallback(
    (setID: string): HTMLElement | null => {
      const index = state.sets.findIndex(set => set.id === setID)
      if (index < 1) {
        return addSetFormButtonRef.current
      }

      const prevSet = state.sets[index - 1]
      const prevSetRef = setRefs.current[`show-grading-period-set-${prevSet.id}`] as
        | {_refs?: {editButton?: Element | null}}
        | undefined
      const editButton = prevSetRef?._refs?.editButton
      return editButton instanceof HTMLElement ? editButton : null
    },
    [state.sets],
  )

  const removeGradingPeriodSet = useCallback(
    (setID: string) => {
      const newSets = reject(state.sets, set => set.id === setID)
      const nodeToFocus = nodeToFocusOnAfterSetDeletion(setID)
      setState({sets: newSets})

      requestAnimationFrame(() => {
        nodeToFocus?.focus()
      })
    },
    [state.sets, nodeToFocusOnAfterSetDeletion, setState],
  )

  const updateSetPeriods = useCallback(
    (setID: string, gradingPeriods: GradingPeriodSetData['gradingPeriods']) => {
      const newSets = state.sets.map(set => {
        if (set.id === setID) {
          return {...set, gradingPeriods}
        }
        return set
      })
      setState({sets: newSets})
    },
    [state.sets, setState],
  )

  const openNewSetForm = useCallback(() => {
    setState({showNewSetForm: true})
  }, [setState])

  const closeNewSetForm = useCallback(() => {
    setState({showNewSetForm: false})

    requestAnimationFrame(() => {
      addSetFormButtonRef.current?.focus()
    })
  }, [setState])

  const termsBelongingToActiveSets = useCallback(() => {
    const setIDs = state.sets.map(set => set.id)
    return filter(state.enrollmentTerms, term => {
      const setID = term.gradingPeriodGroupId
      return !!setID && includes(setIDs, setID)
    })
  }, [state.sets, state.enrollmentTerms])

  const termsNotBelongingToActiveSets = useCallback(
    () => difference(state.enrollmentTerms, termsBelongingToActiveSets()),
    [state.enrollmentTerms, termsBelongingToActiveSets],
  )

  const selectableTermsForEditSetForm = useCallback(
    (setID: string) => {
      const termsBelongingToThisSet = filter(termsBelongingToActiveSets(), {
        gradingPeriodGroupId: setID,
      })
      return union(termsNotBelongingToActiveSets(), termsBelongingToThisSet)
    },
    [termsBelongingToActiveSets, termsNotBelongingToActiveSets],
  )

  const closeEditSetForm = useCallback(
    (_id: string) => {
      setState({editSet: {id: null, saving: false}})
    },
    [setState],
  )

  const getShowGradingPeriodSetRef = useCallback(
    (set: GradingPeriodSetData) => `show-grading-period-set-${set.id}`,
    [],
  )

  const renderEditGradingPeriodSetForm = useCallback(
    (set: GradingPeriodSetData) => {
      const cancelCallback = () => {
        closeEditSetForm(set.id)
      }

      const saveCallback = (editedSet: {
        id?: string
        title: string
        weighted: boolean
        displayTotalsForAllGradingPeriods: boolean
        enrollmentTermIDs: string[]
      }) => {
        if (!editedSet.id) return

        setState({editSet: {...state.editSet, saving: true}})
        const payload: GradingPeriodSetUpdateParams = {
          id: editedSet.id,
          title: editedSet.title,
          weighted: editedSet.weighted,
          displayTotalsForAllGradingPeriods: editedSet.displayTotalsForAllGradingPeriods,
          enrollmentTermIDs: editedSet.enrollmentTermIDs,
        }

        SetsApi.update(payload)
          .then(updated => {
            onSetUpdated(normalizeSet(updated as CamelizedGradingPeriodSet))
            closeEditSetForm(set.id)
          })
          .catch(_ => {
            $.flashError(I18n.t('An error occured while updating the grading period set.'))
            setState({editSet: {id: editedSet.id ?? null, saving: false}})
          })
      }

      return (
        <EditGradingPeriodSetForm
          key={set.id}
          ref={ref => {
            setRefs.current[getEditGradingPeriodSetRef(set)] = ref
          }}
          set={set}
          enrollmentTerms={selectableTermsForEditSetForm(set.id)}
          disabled={state.editSet.saving}
          onCancel={cancelCallback}
          onSave={saveCallback}
        />
      )
    },
    [state.editSet, setState, onSetUpdated, closeEditSetForm, selectableTermsForEditSetForm],
  )

  const renderNewGradingPeriodSetForm = useCallback(() => {
    if (!state.showNewSetForm) return null

    return (
      <NewGradingPeriodSetForm
        closeForm={closeNewSetForm}
        urls={urls}
        enrollmentTerms={termsNotBelongingToActiveSets()}
        addGradingPeriodSet={addGradingPeriodSet}
      />
    )
  }, [
    state.showNewSetForm,
    urls,
    termsNotBelongingToActiveSets,
    addGradingPeriodSet,
    closeNewSetForm,
  ])

  const renderAddSetFormButton = useCallback(() => {
    const disable = state.showNewSetForm || !!state.editSet.id
    if (!readOnly) {
      return (
        <Button
          elementRef={ref => {
            addSetFormButtonRef.current = ref as HTMLButtonElement | null
          }}
          color="primary"
          disabled={disable}
          onClick={openNewSetForm}
          aria-label={I18n.t('Add Set of Grading Periods')}
        >
          <PresentationContent>
            <i className="icon-plus" />
            &nbsp;
            {I18n.t('Set of Grading Periods')}
          </PresentationContent>
        </Button>
      )
    }

    return null
  }, [state.showNewSetForm, state.editSet.id, readOnly, openNewSetForm])

  const renderSets = useCallback(() => {
    const urlsForSet = {
      batchUpdateURL: urls.gradingPeriodsUpdateURL,
      gradingPeriodSetsURL: urls.gradingPeriodSetsURL,
      deleteGradingPeriodURL: urls.deleteGradingPeriodURL,
    }

    return getVisibleSets().map(set => {
      if (state.editSet.id === set.id) {
        return renderEditGradingPeriodSetForm(set)
      }

      return (
        <GradingPeriodSet
          key={set.id}
          ref={ref => {
            setRefs.current[getShowGradingPeriodSetRef(set)] = ref
          }}
          set={set}
          gradingPeriods={set.gradingPeriods}
          urls={urlsForSet}
          actionsDisabled={!!state.editSet.id}
          readOnly={readOnly}
          permissions={set.permissions}
          terms={state.enrollmentTerms}
          expanded={includes(state.expandedSetIDs, set.id)}
          onEdit={editGradingPeriodSet}
          onDelete={removeGradingPeriodSet}
          onPeriodsChange={updateSetPeriods}
          onToggleBody={() => toggleSetBody(set.id)}
        />
      )
    })
  }, [
    urls,
    state.editSet.id,
    state.expandedSetIDs,
    state.enrollmentTerms,
    readOnly,
    getVisibleSets,
    renderEditGradingPeriodSetForm,
    getShowGradingPeriodSetRef,
    editGradingPeriodSet,
    removeGradingPeriodSet,
    updateSetPeriods,
    toggleSetBody,
  ])

  return (
    <div>
      <div className="GradingPeriodSets__toolbar header-bar no-line ic-Form-action-box">
        <div className="ic-Form-action-box__Form">
          <div className="ic-Form-control">
            <EnrollmentTermsDropdown
              terms={termsBelongingToActiveSets()}
              changeSelectedEnrollmentTerm={changeSelectedEnrollmentTerm}
            />
          </div>

          <SearchGradingPeriodsField changeSearchText={changeSearchText} />
          <div className="ic-Form-action-box__Actions">{renderAddSetFormButton()}</div>
        </div>
      </div>

      {renderNewGradingPeriodSetForm()}
      <div id="grading-period-sets">{renderSets()}</div>
    </div>
  )
}

export default GradingPeriodSetCollection
