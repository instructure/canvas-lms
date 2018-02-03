#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'Backbone'
  'jst/searchView'
  './SearchMixin'
], ($, Backbone, template, SearchMixin) ->

  ##
  # Base class for search/filter views. Simply wires up an
  # inputFilterView to fetch a collecion, which then renders the
  # collectionView. You will most certainly want a different template

  class SearchView extends Backbone.View

    @mixin SearchMixin

    ##
    # An InputFilterView

    @child 'inputFilterView', '.inputFilterView'

    ##
    # A CollectionView (and its sub-classes that don't break the
    # substitution rule like PaginatedCollectionView)

    @child 'collectionView', '.collectionView'

    ##
    # You probably don't want this template, but need the elements
    # found therein.

    template: template

    toJSON: ->
      collection: @collection

