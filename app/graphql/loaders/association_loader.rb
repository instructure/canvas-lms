#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

##
# Batch-loads AR associations on a collection of objects (Just like using
# +ActiveRecord::Associations::Preloader+, but this accumulates the list of
# objects to preload for you).
#
# Example:
#
#     # preloads the user and its pseudonym for an enrollment
#     Loaders::AssociationLoader.for(Enrollment, user: :pseudonym).
#       load(some_enrollment).
#       then do
#         # some_enrollment.user and some_enrollment.user.pseudonym
#         # are pre-loaded before this block is called
#       end
class Loaders::AssociationLoader < GraphQL::Batch::Loader
  # +_model+ is the AR model of the object you are going to preload
  # associations onto
  #
  # +associations+ are the associations to preload (this can anything that
  # +ActiveRecord::Associations::Preloader+ accepts)
  def initialize(_model, associations)
    @associations = associations
  end

  # :nodoc:
  def perform(objects)
    ActiveRecord::Associations::Preloader.new.preload(objects, @associations)
    objects.each { |o| fulfill(o, o) }
  end
end
