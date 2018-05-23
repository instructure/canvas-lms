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

import {
  MaintainScrollPositionWhenScrollingIntoThePast,
  ScrollToNewActivity,
  ScrollToLastLoadedNewActivity,
  ContinueInitialLoad,
  FocusItemOnSave,
  FocusPriorItemOnLoadMore,
  FocusPriorItemOnDelete,
  ReturnFocusOnCancelEditing,
  // SetDismissedOpportunityFocus,

  ScrollToToday,
  ScrollToLoadedToday
} from './animations';

export class AnimationCollection {
  static actionsToAnimations = [
    {
      expected: [
        'CONTINUE_LOADING_INITIAL_ITEMS',
        'START_LOADING_FUTURE_SAGA',
        'GOT_DAYS_SUCCESS',
      ],
      animation: ContinueInitialLoad,
    },
    {
      expected: [
        'SCROLL_TO_NEW_ACTIVITY',
      ],
      animation: ScrollToNewActivity,
    },
    {
      expected: [
        'START_LOADING_PAST_UNTIL_NEW_ACTIVITY_SAGA',
        'GOT_DAYS_SUCCESS',
      ],
      animation: ScrollToLastLoadedNewActivity
    },
    {
      expected: [
        'SCROLL_INTO_PAST',
        'START_LOADING_PAST_SAGA',
        'GOT_DAYS_SUCCESS',
      ],
      animation: MaintainScrollPositionWhenScrollingIntoThePast,
    },
    {
      expected: [
        'GETTING_FUTURE_ITEMS', // checks if the load more button was initiator of this action
        'GOT_DAYS_SUCCESS',
      ],
      animation: FocusPriorItemOnLoadMore,
    },
    {
      expected: [
        'SAVED_PLANNER_ITEM',
      ],
      animation: FocusItemOnSave,
    },
    {
      expected: [
        'OPEN_EDITING_PLANNER_ITEM',
        'CANCEL_EDITING_PLANNER_ITEM',
      ],
      animation: ReturnFocusOnCancelEditing,
    },
    {
      expected: [
        'DELETED_PLANNER_ITEM',
      ],
      animation: FocusPriorItemOnDelete,
    },


    // animations for the future. no, the format doesn't match.
    // [['DISMISSED_OPPORTUNITY',
    // ], SetDismissedOpportunityFocus],

    {
      expected: [
        'SCROLL_TO_TODAY',
      ],
      animation: ScrollToToday,
    },
    {
      expected: [
        'START_LOADING_PAST_UNTIL_TODAY_SAGA',
        'GOT_DAYS_SUCCESS',
      ],
      animation: ScrollToLoadedToday
    }
  ]

  constructor (manager, actionsToAnimations) {
    actionsToAnimations.forEach(({expected: expectedEvents, animation: AnimationClass}) => {
      this.animations.push(new AnimationClass(expectedEvents, manager));
    });
  }
  animations = []

  static expectedActionsFor (animationClass) {
    const mapping = AnimationCollection.actionsToAnimations.find(entry => {
      return entry.animation === animationClass;
    });
    return mapping.expected;
  }

  acceptAction (action) {
    this.animations.forEach(animation => {
      animation.acceptAction(action);
    });
  }

  uiWillUpdate () {
    this.animations.forEach(animation => {
      if (animation.isReady()) animation.invokeUiWillUpdate();
    });
  }

  uiDidUpdate () {
    this.animations.forEach(animation => {
      if (animation.isReady()) {
        animation.invokeUiDidUpdate();
      }
    });
  }
}
