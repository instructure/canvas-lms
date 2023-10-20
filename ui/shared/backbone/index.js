/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

// ///
// if you want Backbone, import 'Backbone' (this file). It will give you
// back a Backbone with all of our instructure specific patches to it.

import Backbone from 'backbone'
import {patch as patch1} from './Backbone.syncWithMultipart'
import {patch as patch2} from './Model'
import {patch as patch3} from './View'
import {patch as patch4} from './Collection'

// Apply all of our patches
patch1(Backbone)
patch2(Backbone)
patch3(Backbone)
patch4(Backbone)

export const syncWithMultipart = Backbone.syncWithMultipart
export const Model = Backbone.Model
export const Collection = Backbone.Collection
export const View = Backbone.View

export default Backbone
