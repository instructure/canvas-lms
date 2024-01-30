// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Action} from 'redux'
import {ThunkAction} from 'redux-thunk'
import {showFlashAlert, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import {captureException} from '@sentry/browser'

import {
  CoursePaceItemDueDates,
  CoursePace,
  PaceContextTypes,
  APIPaceContextTypes,
  Progress,
  StoreState,
} from '../types'
import {createAction, ActionsUnion} from '../shared/types'
import {actions as uiActions} from './ui'
import {actions as blackoutDateActions} from '../shared/actions/blackout_dates'
import {getBlackoutDatesUnsynced} from '../shared/reducers/blackout_dates'
import * as Api from '../api/course_pace_api'
import {transformBlackoutDatesForApi} from '../api/blackout_dates_api'
import {getPaceName, getIsUnpublishedNewPace} from '../reducers/course_paces'
import {paceContextsActions} from './pace_contexts'

const I18n = useI18nScope('course_paces_actions')

export const PUBLISH_STATUS_POLLING_MS = 3000
const TERMINAL_PROGRESS_STATUSES = ['completed', 'failed']

export enum Constants {
  SET_END_DATE = 'COURSE_PACE/SET_END_DATE',
  SET_START_DATE = 'COURSE_PACE/SET_START_DATE',
  PUBLISH_PACE = 'COURSE_PACE/PUBLISH_PACE',
  TOGGLE_EXCLUDE_WEEKENDS = 'COURSE_PACE/TOGGLE_EXCLUDE_WEEKENDS',
  SAVE_COURSE_PACE = 'COURSE_PACE/SAVE',
  COURSE_PACE_SAVED = 'COURSE_PACE/SAVED',
  PACE_CREATED = 'COURSE_PACE/PACE_CREATED',
  RESET_PACE = 'COURSE_PACE/RESET_PACE',
  SET_PROGRESS = 'COURSE_PACE/SET_PROGRESS',
  SET_COMPRESSED_ITEM_DATES = 'COURSE_PACE/SET_COMPRESSED_ITEM_DATES',
  UNCOMPRESS_DATES = 'COURSE_PACE/UNCOMPRESS_ITEM_DATES',
}

/* Action creators */

type LoadingAfterAction = (pace: CoursePace) => any

const regularActions = {
  saveCoursePace: (pace: CoursePace) => createAction(Constants.SAVE_COURSE_PACE, pace),
  setStartDate: (date: string) => createAction(Constants.SET_START_DATE, date),
  setCompressedItemDates: (compressedItemDates: CoursePaceItemDueDates) =>
    createAction(Constants.SET_COMPRESSED_ITEM_DATES, compressedItemDates),
  uncompressDates: () => createAction(Constants.UNCOMPRESS_DATES),
  paceCreated: (pace: CoursePace) => createAction(Constants.PACE_CREATED, pace),
  toggleExcludeWeekends: () => createAction(Constants.TOGGLE_EXCLUDE_WEEKENDS),
  resetPace: (originalPace: CoursePace) => createAction(Constants.RESET_PACE, originalPace),
  setProgress: (progress?: Progress) => createAction(Constants.SET_PROGRESS, progress),
  coursePaceSaved: (coursePace: CoursePace) =>
    createAction(Constants.COURSE_PACE_SAVED, coursePace),
}

const thunkActions = {
  onResetPace: (): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(blackoutDateActions.resetBlackoutDates())
      const originalPace = getState().original.coursePace
      return dispatch(regularActions.resetPace(originalPace))
    }
  },
  publishPace: (): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(uiActions.startSyncing())
      dispatch(uiActions.clearCategoryError('publish'))

      return Api.publish(getState().coursePace)
        .then(responseBody => {
          if (!responseBody) throw new Error(I18n.t('Response body was empty'))
          const {course_pace: updatedPace, progress} = responseBody
          dispatch(coursePaceActions.saveCoursePace(updatedPace))
          dispatch(coursePaceActions.setProgress(progress))
          dispatch(coursePaceActions.pollForPublishStatus())
          dispatch(
            paceContextsActions.addPublishingPace({
              progress_context_id: progress.context_id,
              pace_context: getState().paceContexts.selectedContext!,
              polling: true,
            })
          )
          dispatch(uiActions.syncingCompleted())
        })
        .catch(error => {
          dispatch(uiActions.setCategoryError('publish', error?.toString()))
          dispatch(uiActions.syncingCompleted())
        })
    }
  },
  // TODO: when blackout dates are changed we have to possibly publish changes
  // to the pace in the UI + save all existing paces
  publishPaceAndSaveAll: (): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return (dispatch, _getState) => {
      return dispatch(coursePaceActions.publishPace())
    }
  },
  // I have no idea how to declare the return type of this function
  // an error message said: ThunkDispatch<StoreState, void, Action>
  // but that just moved the error
  syncUnpublishedChanges: () => {
    return (dispatch, getState) => {
      dispatch(uiActions.clearCategoryError('publish'))

      if (getBlackoutDatesUnsynced(getState())) {
        dispatch(uiActions.startSyncing())
        return dispatch(blackoutDateActions.syncBlackoutDates())
          .then(() => {
            return dispatch(coursePaceActions.publishPaceAndSaveAll()).then(() => {
              dispatch(uiActions.syncingCompleted())
            })
          })
          .catch(() => {
            dispatch(uiActions.syncingCompleted())
          })
      } else {
        return dispatch(coursePaceActions.publishPace())
      }
    }
  },
  pollForPublishStatus: (): ThunkAction<void, StoreState, void, Action> => {
    // Give the thunk function a name so that we can assert on it in tests
    return function pollingThunk(dispatch, getState) {
      const progress = getState().coursePace.publishingProgress

      const isUnpublishedNewPace = getIsUnpublishedNewPace(getState())
      if (!progress || TERMINAL_PROGRESS_STATUSES.includes(progress.workflow_state)) return

      const pollingLoop = () =>
        Api.getPublishProgress(progress.id)
          .then(updatedProgress => {
            if (!updatedProgress) throw new Error(I18n.t('Response body was empty'))
            const paceContext = getState().paceContexts.contextsPublishing.find(
              ({progress_context_id}) => updatedProgress.context_id === progress_context_id
            )?.pace_context
            const paceName = paceContext?.name || ''
            dispatch(
              coursePaceActions.setProgress(
                updatedProgress.workflow_state !== 'completed' ? updatedProgress : undefined
              )
            )
            dispatch(uiActions.clearCategoryError('checkPublishStatus'))
            if (updatedProgress.workflow_state === 'completed') {
              showFlashAlert({
                message: isUnpublishedNewPace
                  ? I18n.t('%{paceName} Pace created', {paceName})
                  : I18n.t('%{paceName} Pace updated', {paceName}),
                err: null,
                type: 'success',
              })
              dispatch(coursePaceActions.coursePaceSaved(getState().coursePace))
              dispatch(paceContextsActions.refreshPublishedContext(updatedProgress.context_id))
            } else if (updatedProgress.workflow_state === 'failed') {
              showFlashAlert({
                message: I18n.t('Error updating %{paceName}', {paceName}),
                err: null,
                type: 'error',
              })
              dispatch(uiActions.setCategoryError('publish'))
              dispatch(paceContextsActions.refreshPublishedContext(updatedProgress.context_id))
              console.log(`Error publishing pace: ${updatedProgress.message}`) // eslint-disable-line no-console
            } else {
              setTimeout(pollingLoop, PUBLISH_STATUS_POLLING_MS)
            }
          })
          .catch(error => {
            dispatch(uiActions.setCategoryError('checkPublishStatus', error?.toString()))
            console.log(error) // eslint-disable-line no-console
          })
      return pollingLoop()
    }
  },
  resetToLastPublished: (
    contextType: PaceContextTypes,
    contextId: string
  ): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay(I18n.t('Loading...')))
      dispatch(uiActions.clearCategoryError('resetToLastPublished'))

      await Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.resetToLastPublished(contextType, contextId)
        .then(coursePace => {
          if (!coursePace) throw new Error(I18n.t('Response body was empty'))
          dispatch(coursePaceActions.saveCoursePace(coursePace))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setCategoryError('resetToLastPublished', error?.toString()))
          console.error(error) // eslint-disable-line no-console
          captureException(error)
        })
    }
  },
  loadLatestPaceByContext: (
    contextType: PaceContextTypes,
    contextId: string,
    afterAction: LoadingAfterAction = coursePaceActions.saveCoursePace,
    openModal: boolean = true
  ): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      if (openModal) {
        dispatch(uiActions.showLoadingOverlay(I18n.t('Loading...')))
        dispatch(uiActions.clearCategoryError('loading'))
      }

      await Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.getNewCoursePaceFor(getState().course.id, contextType, contextId)
        .then(({course_pace: coursePace, progress}) => {
          if (!coursePace) throw new Error(I18n.t('Response body was empty'))
          if (afterAction) {
            dispatch(afterAction(coursePace))
          }
          dispatch(coursePaceActions.setProgress(progress))
          dispatch(coursePaceActions.pollForPublishStatus())
          if (openModal) {
            dispatch(uiActions.hideLoadingOverlay())
            dispatch(uiActions.showPaceModal(coursePace))
          }
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setCategoryError('loading', error?.toString()))
          console.error(error) // eslint-disable-line no-console
          captureException(error)
        })
    }
  },
  relinkToParentPace: (): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      const coursePaceId = getState().coursePace.id
      if (!coursePaceId) return Promise.reject(new Error(I18n.t('Cannot relink unsaved paces')))

      dispatch(uiActions.showLoadingOverlay(I18n.t('Relinking paces...')))
      dispatch(uiActions.clearCategoryError('relinkToParent'))

      await Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.relinkToParentPace(coursePaceId)
        .then(coursePace => {
          if (!coursePace) throw new Error(I18n.t('Response body was empty'))
          dispatch(coursePaceActions.saveCoursePace(coursePace))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setCategoryError('relinkToParent', error?.toString()))
          console.error(error) // eslint-disable-line no-console
          captureException(error)
        })
    }
  },
  compressDates: (): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay(I18n.t('Compressing...')))
      dispatch(uiActions.clearCategoryError('compress'))

      const state = getState()
      return Api.compress(state.coursePace, {
        blackout_dates: transformBlackoutDatesForApi(state.blackoutDates.blackoutDates),
      })
        .then(responseBody => {
          if (!responseBody) throw new Error(I18n.t('Response body was empty'))
          const compressedItemDates = responseBody
          dispatch(coursePaceActions.setCompressedItemDates(compressedItemDates))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setCategoryError('compress', error?.toString()))
          console.log(error) // eslint-disable-line no-console
        })
    }
  },
  removePace: (): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay(I18n.t('Removing pace...')))
      dispatch(uiActions.clearCategoryError('removePace'))

      const paceName = getPaceName(getState())
      const CONTEXT_TYPE_MAP: {[k in PaceContextTypes]: APIPaceContextTypes} = {
        Course: 'course',
        Section: 'section',
        Enrollment: 'student_enrollment',
      }
      const selectedContextType = CONTEXT_TYPE_MAP[getState().ui.selectedContextType]
      return Api.removePace(getState().coursePace)
        .then(() => {
          const {page, searchTerm, sortBy, order} = getState().paceContexts
          dispatch(uiActions.hidePaceModal())

          dispatch(
            paceContextsActions.fetchPaceContexts({
              contextType: selectedContextType,
              page,
              searchTerm,
              sortBy,
              orderType: order,
            })
          )
          showFlashSuccess(I18n.t('%{paceName} Pace removed', {paceName}))()
        })
        .catch(error => {
          dispatch(uiActions.setCategoryError('removePace', error?.toString()))
        })
        .finally(() => {
          dispatch(uiActions.hideLoadingOverlay())
        })
    }
  },
}

export const coursePaceActions = {...regularActions, ...thunkActions}
export type CoursePaceAction = ActionsUnion<typeof regularActions>
