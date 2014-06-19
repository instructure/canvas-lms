#
# Copyright (C) 2013 Instructure, Inc.
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

module LtiOutbound
  class VariableSubstitutor

    class << self
      attr_accessor :substitutions

      def add_substitution(key, model, method)
        self.substitutions ||= {}
        self.substitutions[key] = {method: method, model: model}
      end

    end


    #Variable Substitutions
    #
    #Account
    add_substitution '$Canvas.account.id', :account, :id
    add_substitution '$Canvas.account.name', :account, :name
    add_substitution '$Canvas.account.sisSourceId', :account, :sis_source_id
    #Assignment
    add_substitution '$Canvas.assignment.id', :assignment, :id
    add_substitution '$Canvas.assignment.title', :assignment, :title
    add_substitution '$Canvas.assignment.pointsPossible', :assignment, :points_possible
    #Consumer Instance
    add_substitution '$Canvas.root_account.id', :consumer_instance, :id
    add_substitution '$Canvas.root_account.sisSourceId', :consumer_instance, :sis_source_id
    add_substitution '$Canvas.api.domain', :consumer_instance, :domain
    #Course
    add_substitution '$Canvas.course.id', :course, :id
    add_substitution '$Canvas.course.sisSourceId', :course, :sis_source_id
    #User
    add_substitution '$Canvas.user.id', :user, :id
    add_substitution '$Canvas.user.sisSourceId', :user, :sis_source_id
    add_substitution '$Canvas.user.loginId', :user, :login_id
    add_substitution '$Canvas.enrollment.enrollmentState', :user, :enrollment_state
    add_substitution '$Canvas.membership.concludedRoles', :user, :concluded_role_types
    add_substitution '$Person.name.family', :user, :last_name
    add_substitution '$Person.name.full', :user, :name
    add_substitution '$Person.name.given', :user, :first_name
    add_substitution '$Person.address.timezone', :user, :timezone


    attr_reader :substitution_objects

    def initialize(substitution_objects)
      @substitution_objects = substitution_objects
    end

    def substitute!(data_hash)
      data_hash.each do |k, v|
        if value = substitution_value(v)
          data_hash[k] = value
        end
      end
      data_hash
    end


    private

    def substitution_value(key)
      lookup = VariableSubstitutor.substitutions[key]
      if model = lookup && lookup_model(lookup[:model])
        model.send(lookup[:method])
      end
    end

    def lookup_model(model_name)
      if model_name == :course && substitution_objects[:context].is_a?(LtiOutbound::LTICourse)
        model_name = :context
      end
      substitution_objects[model_name]
    end

  end
end