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
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  CoursePaceItemDueDates,
  CoursePace,
  PaceContextTypes,
  Progress,
  StoreState,
  OptionalDate
} from '../types'
import {createAction, ActionsUnion} from '../shared/types'
import {actions as uiActions} from './ui'
import {actions as blackoutDateActions} from '../shared/actions/blackout_dates'
import {getBlackoutDatesUnsynced} from '../shared/reducers/blackout_dates'
import * as Api from '../api/course_pace_api'

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
  TOGGLE_HARD_END_DATES = 'COURSE_PACE/TOGGLE_HARD_END_DATES',
  RESET_PACE = 'COURSE_PACE/RESET_PACE',
  SET_PROGRESS = 'COURSE_PACE/SET_PROGRESS',
  SET_COMPRESSED_ITEM_DATES = 'COURSE_PACE/SET_COMPRESSED_ITEM_DATES',
  UNCOMPRESS_DATES = 'COURSE_PACE/UNCOMPRESS_ITEM_DATES'
}

/* Action creators */

type LoadingAfterAction = (pace: CoursePace) => any
// Without this, we lose the ReturnType through our mapped ActionsUnion (because of setPaceDays), and the type just becomes any.
type SetEndDate = {type: Constants.SET_END_DATE; payload: string}

const regularActions = {
  saveCoursePace: (pace: CoursePace) => createAction(Constants.SAVE_COURSE_PACE, pace),
  setStartDate: (date: string) => createAction(Constants.SET_START_DATE, date),
  setEndDate: (date: string): SetEndDate => createAction(Constants.SET_END_DATE, date),
  setCompressedItemDates: (compressedItemDates: CoursePaceItemDueDates) =>
    createAction(Constants.SET_COMPRESSED_ITEM_DATES, compressedItemDates),
  uncompressDates: () => createAction(Constants.UNCOMPRESS_DATES),
  paceCreated: (pace: CoursePace) => createAction(Constants.PACE_CREATED, pace),
  toggleExcludeWeekends: () => createAction(Constants.TOGGLE_EXCLUDE_WEEKENDS),
  toggleHardEndDates: (original_end_date: OptionalDate) =>
    createAction(Constants.TOGGLE_HARD_END_DATES, original_end_date),
  resetPace: (originalPace: CoursePace) => createAction(Constants.RESET_PACE, originalPace),
  setProgress: (progress?: Progress) => createAction(Constants.SET_PROGRESS, progress),
  coursePaceSaved: (coursePace: CoursePace) => createAction(Constants.COURSE_PACE_SAVED, coursePace)
}

const thunkActions = {
  onToggleHardEndDates: (): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, getState) => {
      const originalEndDate = getState().original.coursePace.end_date
      return dispatch(regularActions.toggleHardEndDates(originalEndDate))
    }
  },
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

      if (ENV.FEATURES.course_paces_blackout_dates && getBlackoutDatesUnsynced(getState())) {
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
      if (!progress || TERMINAL_PROGRESS_STATUSES.includes(progress.workflow_state)) return

      const pollingLoop = () =>
        Api.getPublishProgress(progress.id)
          .then(updatedProgress => {
            if (!updatedProgress) throw new Error(I18n.t('Response body was empty'))
            dispatch(
              coursePaceActions.setProgress(
                updatedProgress.workflow_state !== 'completed' ? updatedProgress : undefined
              )
            )
            dispatch(uiActions.clearCategoryError('checkPublishStatus'))
            if (TERMINAL_PROGRESS_STATUSES.includes(updatedProgress.workflow_state)) {
              showFlashAlert({
                message: I18n.t('Finished publishing pace'),
                err: null,
                type: 'success',
                srOnly: true
              })
              dispatch(coursePaceActions.coursePaceSaved(getState().coursePace))
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
        })
    }
  },
  loadLatestPaceByContext: (
    contextType: PaceContextTypes,
    contextId: string,
    afterAction: LoadingAfterAction = coursePaceActions.saveCoursePace
  ): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay(I18n.t('Loading...')))
      dispatch(uiActions.clearCategoryError('loading'))

      await Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.getNewCoursePaceFor(getState().course.id, contextType, contextId)
        .then(coursePace => {
          if (!coursePace) throw new Error(I18n.t('Response body was empty'))
          dispatch(afterAction(coursePace))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setCategoryError('loading', error?.toString()))
          console.error(error) // eslint-disable-line no-console
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
        })
    }
  },
  compressDates: (): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay(I18n.t('Compressing...')))
      dispatch(uiActions.clearCategoryError('compress'))

      return Api.compress(getState().coursePace)
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
  }
}

export const coursePaceActions = {...regularActions, ...thunkActions}
export type CoursePaceAction = ActionsUnion<typeof regularActions>
