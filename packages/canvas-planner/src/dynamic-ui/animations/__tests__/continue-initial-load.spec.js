/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {ContinueInitialLoad} from '../index';
import {createAnimation} from './test-utils';
import * as actions from '../../../actions';

jest.mock('../../../actions');
jest.useFakeTimers();

function createReadyAnimation () {
  const {continueLoadingInitialItems, startLoadingFutureSaga, gotDaysSuccess} =
    require.requireActual('../../../actions');
  const result = createAnimation(ContinueInitialLoad);
  result.animation.acceptAction(continueLoadingInitialItems());
  result.animation.acceptAction(startLoadingFutureSaga());
  result.animation.acceptAction(gotDaysSuccess('some data'));
  return result;
}

afterEach(() => {
  jest.resetAllMocks();
});

it('keeps loading if the screen is not full and there are more items to load', () => {
  const {animation, store, animator} = createReadyAnimation();
  store.getState.mockReturnValue({loading: {allFutureItemsLoaded: false}});
  animator.isOnScreen.mockReturnValue(true);
  actions.continueLoadingInitialItems.mockReturnValue('clii');
  actions.loadFutureItems.mockReturnValue('lfi');
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  jest.runAllTimers();
  expect(store.dispatch).toHaveBeenCalledWith('clii');
  expect(store.dispatch).toHaveBeenCalledWith('lfi');
});

it('stops loading if the screen is full', () => {
  const {animation, store, animator} = createReadyAnimation();
  store.getState.mockReturnValue({loading: {allFutureItemsLoaded: false}});
  animator.isOnScreen.mockReturnValue(false);
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  jest.runAllTimers();
  expect(actions.continueLoadingInitialItems).not.toHaveBeenCalled();
  expect(actions.loadFutureItems).not.toHaveBeenCalled();
  expect(store.dispatch).not.toHaveBeenCalled();
});

it('stops loading if all items have been loaded', () => {
  const {animation, store, animator} = createReadyAnimation();
  store.getState.mockReturnValue({loading: {allFutureItemsLoaded: true}});
  animator.isOnScreen.mockReturnValue(true);
  actions.continueLoadingInitialItems.mockReturnValue('clii');
  actions.loadFutureItems.mockReturnValue('lfi');
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  jest.runAllTimers();
  expect(actions.continueLoadingInitialItems).not.toHaveBeenCalled();
  expect(actions.loadFutureItems).not.toHaveBeenCalled();
  expect(store.dispatch).not.toHaveBeenCalled();
});
