/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import todoReducer from '../todo-reducer';

function basicTodo (options = {}) {
  return {
    theme:{
      iconColor: "#629f56"
    },
    color: "#629f56",
    id: "6",
    courseName: "Chat",
    context:{
      type: "Planner Note",
      id: "1",
      title: "Chat",
      image_url: null,
      color: "#629f56",
      url: "/courses/1"
    },
    date: "2017-06-22T14:32:22.000Z",
    associated_item: "To Do",
    title: "asdfasdfsdf",
    badges: [],
    ...options
  };
}

it('adds todo notes to the state on UPDATE_TODO', () => {
  const initialState = {};

  const newState = todoReducer(initialState, {
    type: 'UPDATE_TODO',
    payload: basicTodo()
  });

  expect(newState.id).toBe('6');
});

it('clears the todo note item on CLEAR_UPDATE_TODO', () => {
  const initialState = basicTodo();
  const newState = todoReducer(initialState, {
    type: 'CLEAR_UPDATE_TODO'
  });
  expect(newState).toEqual({});
});

it('sets a default updateTodoItem if missing', () => {
  const initialState = basicTodo();
  const newState = todoReducer(initialState, {
    type: 'OPEN_EDITING_PLANNER_ITEM'
  });
  expect(newState.updateTodoItem).toBeDefined;
});

it('leaves existing updateTodoItem alone if provided', () => {
  const updateTodoItem = {title: 'foo'};
  const initialState = basicTodo({updateTodoItem});
  const newState = todoReducer(initialState, {
    type: 'OPEN_EDITING_PLANNER_ITEM'
  });
  expect(newState.updateTodoItem).toEqual(updateTodoItem);
});