# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# @API Users
# @subtopic Custom Data
class CustomDataController < ApplicationController
  before_action :require_namespace, :get_scope, :get_context
  before_action :require_custom_data, except: :set_data

  # @API Store custom data
  # Store arbitrary user data as JSON.
  #
  # Arbitrary JSON data can be stored for a User.
  # A typical scenario would be an external site/service that registers users in Canvas
  # and wants to capture additional info about them.  The part of the URL that follows
  # +/custom_data/+ defines the scope of the request, and it reflects the structure of
  # the JSON data to be stored or retrieved.
  #
  # The value +self+ may be used for +user_id+ to store data associated with the calling user.
  # In order to access another user's custom data, you must be an account administrator with
  # permission to manage users.
  #
  # A namespace parameter, +ns+, is used to prevent custom_data collisions between
  # different apps.  This parameter is required for all custom_data requests.
  #
  # A request with Content-Type multipart/form-data or Content-Type
  # application/x-www-form-urlencoded can only be used to store strings.
  #
  # Example PUT with multipart/form-data data:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/telephone' \
  #     -X PUT \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -F 'data=555-1234' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": "555-1234"
  #   }
  #
  # Subscopes (or, generated scopes) can also be specified by passing values to
  # +data+[+subscope+].
  #
  # Example PUT specifying subscopes:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/body/measurements' \
  #     -X PUT \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -F 'data[waist]=32in' \
  #     -F 'data[inseam]=34in' \
  #     -F 'data[chest]=40in' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": {
  #       "chest": "40in",
  #       "waist": "32in",
  #       "inseam": "34in"
  #     }
  #   }
  #
  # Following such a request, subsets of the stored data to be retrieved directly from a subscope.
  #
  # Example {api:UsersController#get_custom_data GET} from a generated scope
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/body/measurements/chest' \
  #     -X GET \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": "40in"
  #   }
  #
  # If you want to store more than just strings (i.e. numbers, arrays, hashes, true, false,
  # and/or null), you must make a request with Content-Type application/json as in the following
  # example.
  #
  # Example PUT with JSON data:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data' \
  #     -H 'Content-Type: application/json' \
  #     -X PUT \
  #     -d '{
  #           "ns": "com.my-organization.canvas-app",
  #           "data": {
  #             "a-number": 6.02e23,
  #             "a-bool": true,
  #             "a-string": "true",
  #             "a-hash": {"a": {"b": "ohai"}},
  #             "an-array": [1, "two", null, false]
  #           }
  #         }' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": {
  #       "a-number": 6.02e+23,
  #       "a-bool": true,
  #       "a-string": "true",
  #       "a-hash": {
  #         "a": {
  #           "b": "ohai"
  #         }
  #       },
  #       "an-array": [1, "two", null, false]
  #     }
  #   }
  #
  # If the data is an Object (as it is in the above example), then subsets of the data can
  # be accessed by including the object's (possibly nested) keys in the scope of a GET request.
  #
  # Example {api:UsersController#get_custom_data GET} with a generated scope:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/a-hash/a/b' \
  #     -X GET \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": "ohai"
  #   }
  #
  #
  # On success, this endpoint returns an object containing the data that was stored.
  #
  # Responds with status code 200 if the scope already contained data, and it was overwritten
  # by the data specified in the request.
  #
  # Responds with status code 201 if the scope was previously empty, and the data specified
  # in the request was successfully stored there.
  #
  # Responds with status code 400 if the namespace parameter, +ns+, is missing or invalid, or if
  # the +data+ parameter is missing.
  #
  # Responds with status code 409 if the requested scope caused a conflict and data was not stored.
  # This happens when storing data at the requested scope would cause data at an outer scope
  # to be lost.  e.g., if +/custom_data+ was +{"fashion_app": {"hair": "blonde"}}+, but
  # you tried to +`PUT /custom_data/fashion_app/hair/style -F data=buzz`+, then for the request
  # to succeed,the value of +/custom_data/fashion_app/hair+ would have to become a hash, and its
  # old string value would be lost.  In this situation, an error object is returned with the
  # following format:
  #
  #   !!!javascript
  #   {
  #     "message": "write conflict for custom_data hash",
  #     "conflict_scope": "fashion_app/hair",
  #     "type_at_conflict": "String",
  #     "value_at_conflict": "blonde"
  #   }
  #
  # @argument ns [Required, String]
  #   The namespace under which to store the data.  This should be something other
  #   Canvas API apps aren't likely to use, such as a reverse DNS for your organization.
  #
  # @argument data [Required, JSON]
  #   The data you want to store for the user, at the specified scope.  If the data is
  #   composed of (possibly nested) JSON objects, scopes will be generated for the (nested)
  #   keys (see examples).
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/food_app' \
  #     -X PUT \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -F 'data[weight]=81kg' \
  #     -F 'data[favorites][meat]=pork belly' \
  #     -F 'data[favorites][dessert]=pistachio ice cream' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "data": {
  #       "weight": "81kg",
  #       "favorites": {
  #         "meat": "pork belly",
  #         "dessert": "pistachio ice cream"
  #       }
  #     }
  #   }
  def set_data
    return unless authorized_action(@context, @current_user, [:manage, :manage_user_details])

    cd = CustomData.unique_constraint_retry do
      CustomData.where(user_id: @context.id, namespace: @namespace).first_or_create!
    end

    data = params[:data]
    render(json: { message: "no data specified" }, status: :bad_request) and return if data.nil?

    data = data.to_unsafe_h if data.is_a?(ActionController::Parameters)

    saved = false
    overwrite = nil
    begin
      saved = cd.lock_and_save do
        overwrite = cd.set_data(@scope, data)
      end
    rescue CustomData::WriteConflict => e
      render(json: e.as_json.merge(message: e.message), status: :conflict) and return
    end

    if saved
      render(json: { data: cd.get_data(@scope) },
             status: (overwrite ? :ok : :created))
    else
      render(json: cd.errors, status: :bad_request)
    end
  end

  # @API Load custom data
  # Load custom user data.
  #
  # Arbitrary JSON data can be stored for a User.  This API call
  # retrieves that data for a (optional) given scope.
  # See {api:UsersController#set_custom_data Store Custom Data} for details and
  # examples.
  #
  # On success, this endpoint returns an object containing the data that was requested.
  #
  # Responds with status code 400 if the namespace parameter, +ns+, is missing or invalid,
  # or if the specified scope does not contain any data.
  #
  # @argument ns [Required, String]
  #   The namespace from which to retrieve the data.  This should be something other
  #   Canvas API apps aren't likely to use, such as a reverse DNS for your organization.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/food_app/favorites/dessert' \
  #     -X GET \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "data": "pistachio ice cream"
  #   }
  def get_data
    return unless authorized_action(@context, @current_user, :read)

    begin
      data = @cd.get_data @scope
    rescue ArgumentError => e
      render(json: { message: e.message }, status: :bad_request) and return
    end
    render(json: { data: })
  end

  # @API Delete custom data
  # Delete custom user data.
  #
  # Arbitrary JSON data can be stored for a User.  This API call
  # deletes that data for a given scope.  Without a scope, all custom_data is deleted.
  # See {api:UsersController#set_custom_data Store Custom Data} for details and
  # examples of storage and retrieval.
  #
  # As an example, we'll store some data, then delete a subset of it.
  #
  # Example {api:UsersController#set_custom_data PUT} with valid JSON data:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data' \
  #     -X PUT \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -F 'data[fruit][apple]=so tasty' \
  #     -F 'data[fruit][kiwi]=a bit sour' \
  #     -F 'data[veggies][root][onion]=tear-jerking' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": {
  #       "fruit": {
  #         "apple": "so tasty",
  #         "kiwi": "a bit sour"
  #       },
  #       "veggies": {
  #         "root": {
  #           "onion": "tear-jerking"
  #         }
  #       }
  #     }
  #   }
  #
  # Example DELETE:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/fruit/kiwi' \
  #     -X DELETE \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": "a bit sour"
  #   }
  #
  # Example {api:UsersController#get_custom_data GET} following the above DELETE:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data' \
  #     -X GET \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": {
  #       "fruit": {
  #         "apple": "so tasty"
  #       },
  #       "veggies": {
  #         "root": {
  #           "onion": "tear-jerking"
  #         }
  #       }
  #     }
  #   }
  #
  # Note that hashes left empty after a DELETE will get removed from the custom_data store.
  # For example, following the previous commands, if we delete /custom_data/veggies/root/onion,
  # then the entire /custom_data/veggies scope will be removed.
  #
  # Example DELETE that empties a parent scope:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/veggies/root/onion' \
  #     -X DELETE \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": "tear-jerking"
  #   }
  #
  # Example {api:UsersController#get_custom_data GET} following the above DELETE:
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data' \
  #     -X GET \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # Response:
  #   !!!javascript
  #   {
  #     "data": {
  #       "fruit": {
  #         "apple": "so tasty"
  #       }
  #     }
  #   }
  #
  # On success, this endpoint returns an object containing the data that was deleted.
  #
  # Responds with status code 400 if the namespace parameter, +ns+, is missing or invalid,
  # or if the specified scope does not contain any data.
  #
  # @argument ns [Required, String]
  #   The namespace from which to delete the data.  This should be something other
  #   Canvas API apps aren't likely to use, such as a reverse DNS for your organization.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/users/<user_id>/custom_data/fruit/kiwi' \
  #     -X DELETE \
  #     -F 'ns=com.my-organization.canvas-app' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   !!!javascript
  #   {
  #     "data": "a bit sour"
  #   }
  def delete_data
    return unless authorized_action(@context, @current_user, [:manage, :manage_user_details])

    ret = nil
    begin
      saved = @cd.lock_and_save do
        ret = @cd.delete_data(@scope)
      end
    rescue ArgumentError => e
      render(json: { message: e.message }, status: :bad_request) and return
    end

    if saved
      render(json: { data: ret })
    else
      render(json: @cd.errors, status: :bad_request)
    end
  end

  private

  def require_namespace
    @namespace = params[:ns]
    render(json: { message: "invalid namespace" }, status: :bad_request) and return if @namespace.blank?
  end

  def get_scope
    @scope = params[:scope]
  end

  def require_custom_data
    @cd = CustomData.where(user_id: @context.id, namespace: @namespace).first or
      render(json: { message: "no data for scope" }, status: :bad_request)
  end
end
