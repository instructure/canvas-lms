# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module ConditionalRelease
  module Concerns
    module ApiToNestedAttributes
      ##
      # Transforms an input hash into a form acceptable to accepts_nested_attributes_for
      # and adds destroy requests for any associations not specified.
      # * model - ActiveRecord model to update
      #           model class should have accepts_nested_attributes_for set
      #           can be nil to transform params for creation
      # * model_params - nested hash with indifferent access describing model and its associations
      # * association_names - list of association names, one for each level of nesting
      # Returns modified model_params
      # Usage:
      #     Parent accepts_nested_attributes_for :children
      #     Child accepts_nested_attributes_for :grandchildren
      # New parent record:
      # api_params_to_nested_attributes_params(nil, params, :children, :grandchildren)
      #   { name: "abe", children: [ { name: "homer", grandchildren: [ { name: "lisa" }, { name: "bart" } ] } ] }
      #   Needs to be transformed to
      #   { name: "abe", children_attributes: [ { name: "homer", grandchildren_attributes: [ { name: "lisa" }, { name: "bart" } ] } ] }
      # Update parent record:
      # api_params_to_nested_attributes_params(abe_record, params, :children, :grandchildren)
      #   { id: 1, name: "abe", children: [ { id: 2, name: "homer", grandchildren: [ { id: 3, name: "lisa" }, { name: "maggie" } ] } ] }
      #   Needs to be transformed to
      #   { id: 1, name: "abe", children_attributes: [ { id: 2, name: "homer", grandchildren_attributes: [ { id: 3, name: "lisa" }, { id: 4, _destroy: true }, { name: "maggie" } ] } ] }
      def api_params_to_nested_attributes_params(model, model_params, *association_names)
        name, *other_names = *association_names
        return model_params unless name

        collection = model.send(name) if model
        collection_params = model_params.delete(name)
        return model_params unless collection_params

        # recurse on nested associations
        collection_params.each do |association_params|
          association_model = collection.find(association_params[:id]) if collection && association_params[:id]
          api_params_to_nested_attributes_params(association_model, association_params, *other_names)
        end

        # add destroy requests for missing associations
        if collection
          existing_ids = collection.pluck(:id)
          updated_ids = collection_params.pluck(:id).map(&:to_i)
          ids_to_destroy = existing_ids - updated_ids
          ids_to_destroy.each do |id|
            collection_params << { id:, _destroy: true }
          end
        end

        # _attributes to play nice with nested attributes
        model_params["#{name}_attributes"] = collection_params
        model_params
      end
    end
  end
end
