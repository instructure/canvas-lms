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

import Animation from '../animation';
import {continueLoadingInitialItems, loadFutureItems} from '../../actions';

export class ContinueInitialLoad extends Animation {
  uiDidUpdate () {
    const moreItemsToLoad = !this.store().getState().loading.allFutureItemsLoaded;
    const keepLoading = this.animator().isOnScreen(this.app().fixedElementForItemScrolling(), this.stickyOffset());
    if (moreItemsToLoad && keepLoading) {
      // we have to do this after this animation is complete,
      // because these actions can't be received recursively.
      this.window().setTimeout(() => {
        this.store().dispatch(continueLoadingInitialItems()); // so we can invoke this animation again
        this.store().dispatch(loadFutureItems());
      }, 0);
    }
  }
}
