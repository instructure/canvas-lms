// /*
//  * Copyright (C) 2014 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

// define(function(require) {
//   var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
//   var Subject = require('jsx!components/dialog');

//   describe('Components.Dialog', function() {
//     var Contents = React.createClass({
//       render: function() {
//         return React.DOM.p({ children: 'Hello from Dialog!' });
//       }
//     });

//     this.reactSuite({
//       type: Subject
//     });

//     var getDialog = function() {
//       return document.body.querySelector('.ui-dialog');
//     };

//     it('should render', function() {
//       setProps({ content: Contents });

//       expect(getDialog()).toBeTruthy();
//       expect(getDialog().innerText).toMatch('Hello from Dialog!');
//     });

//     it('should pass properties through to the content', function() {
//       setProps({ name: 'Ahmad' }).then(function() {
//         expect(subject.state.content.props.name).toEqual('Ahmad');
//       });
//     });

//     it('should not pass parent-specific props, like @className', function() {
//       setProps({ className: 'test' }).then(function() {
//         expect(subject.props.className).toEqual('test');
//         expect(subject.state.content.props.className).toBeFalsy();
//       });
//     });

//     it('should accept custom tagNames', function() {
//       setProps({ tagName: 'button' });
//       expect(subject.getDOMNode().tagName).toEqual('BUTTON');
//     });

//     describe('#open, #isOpen, #close', function() {
//       it('should work', function() {
//         setProps({ content: Contents });

//         subject.open();
//         expect(subject.isOpen()).toBe(true);
//         expect(getDialog().style.display).toEqual('block');

//         subject.close();
//         expect(subject.isOpen()).toBe(false);
//         expect(getDialog().style.display).toEqual('none');

//         subject.open();
//         expect(subject.isOpen()).toBe(true);
//         expect(getDialog().style.display).toEqual('block');
//       });
//     });
//   });
// });
