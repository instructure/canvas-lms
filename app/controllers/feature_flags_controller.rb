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

# @API Feature Flags
#
# Manage optional features in Canvas
#
# @object Feature
#    {
#      // The symbolic name of the feature, used in FeatureFlags
#      "name": "fancy_wickets",
#
#      // The user-visible name of the feature
#      "display_name": "Fancy Wickets",
#
#      // The type of object the feature applies to (RootAccount, Account, Course, or User):
#      // * RootAccount features may only be controlled by flags on root accounts.
#      // * Account features may be controlled by flags on accounts and their parent accounts.
#      // * Course features may be controlled by flags on courses and their parent accounts.
#      // * User features may be controlled by flags on users and site admin only.
#      "applies_to": "Course",
#
#      // The date this feature will be globally enabled, or null if this is not planned.
#      // (This information is subject to change.)
#      "enable_at": "2014-01-01T00:00:00Z",
#
#      // The FeatureFlag that applies to the caller
#      "feature_flag": {
#        "feature": "fancy_wickets",
#        "state": "allowed",
#        "locking_account_id": null
#      },
#
#      // If true, a feature that is "allowed" globally will be "off" by default in root accounts.
#      // Otherwise, root accounts inherit the global "allowed" setting, which allows sub-accounts
#      // and courses to turn features on with no root account action.
#      "root_opt_in": true,
#
#      // Whether the feature is a beta feature
#      "beta": false,
#
#      // Whether the feature is in development
#      "development": false,
#
#      // A URL to the release notes describing the feature
#      "release_notes_url": "http://canvas.example.com/release_notes#fancy_wickets"
#    }
#
# @object FeatureFlag
#    {
#      // The type of object to which this flag applies (Account, Course, or User).
#      // (This field is not present if this FeatureFlag represents the global Canvas default)
#      "context_type": "Account",
#
#      // The id of the object to which this flag applies
#      // (This field is not present if this FeatureFlag represents the global Canvas default)
#      "context_id": 1038,
#
#      // The feature this flag controls
#      "feature": "fancy_wickets",
#
#      // The policy for the feature at this context.  can be "off", "allowed", or "on".
#      "state": "allowed",
#
#      // If set, this feature flag cannot be changed in the caller's context
#      // because the flag is set "off" or "on" in a higher context, or the flag is locked
#      // by an account the caller does not have permission to administer
#      "locked": false,
#
#      // If set, this FeatureFlag can only be modified by someone with administrative rights
#      // in the specified account
#      "locking_account_id": null
#    }
#
class FeatureFlagsController < ApplicationController
  include Api::V1::FeatureFlag

  before_filter :get_context

  # @API List features
  #
  # List all features that apply to a given Account, Course, or User.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/courses/1/features' \
  #     -H "Authorization: Bearer "
  #
  # @returns [Feature]
  def index
    if authorized_action(@context, @current_user, :read)
      route = polymorphic_url([:api_v1, @context, :features])
      features = Feature.applicable_features(@context)
      features = Api.paginate(features, self, route)
      flags = features.map { |fd|
        @context.lookup_feature_flag(fd.feature, Account.site_admin.grants_right?(@current_user, session, :manage_feature_flags))
      }.compact
      render json: flags.map { |flag| feature_with_flag_json(flag, @context, @current_user, session) }
    end
  end

  # @API List enabled features
  #
  # List all features that are enabled on a given Account, Course, or User.
  # Only the feature names are returned.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/courses/1/features/enabled' \
  #     -H "Authorization: Bearer "
  #
  # @example_response
  #
  #   ["fancy_wickets", "automatic_essay_grading", "telepathic_navigation"]
  def enabled_features
    if authorized_action(@context, @current_user, :read)
      features = Feature.applicable_features(@context).map { |fd| @context.lookup_feature_flag(fd.feature) }.compact.
                   select { |ff| ff.enabled? }.map(&:feature)
      render json: features
    end
  end

  # @API Get feature flag
  #
  # Get the feature flag that applies to a given Account, Course, or User.
  # The flag may be defined on the object, or it may be inherited from a parent
  # account. You can look at the context_id and context_type of the returned object
  # to determine which is the case. If these fields are missing, then the object
  # is the global Canvas default.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/courses/1/features/flags/fancy_wickets' \
  #     -H "Authorization: Bearer "
  #
  # @returns FeatureFlag
  def show
    if authorized_action(@context, @current_user, :read)
      return render json: { message: "missing feature parameter" }, status: :bad_request unless params[:feature].present?
      flag = @context.lookup_feature_flag(params[:feature], Account.site_admin.grants_right?(@current_user, session, :manage_feature_flags))
      raise ActiveRecord::RecordNotFound unless flag
      render json: feature_flag_json(flag, @context, @current_user, session)
    end
  end

  # @API Set feature flag
  #
  # Set a feature flag for a given Account, Course, or User. This call will fail if a parent account sets
  # a feature flag for the same feature in any state other than "allowed".
  #
  # @argument state [Optional, String, "off"|"allowed"|"on"]
  #   "off":: The feature is not available for the course, user, or account and sub-accounts.
  #   "allowed":: (valid only on accounts) The feature is off in the account, but may be enabled in
  #               sub-accounts and courses by setting a feature flag on the sub-account or course.
  #   "on":: The feature is turned on unconditionally for the user, course, or account and sub-accounts.
  #
  # @argument locking_account_id [Optional, Integer]
  #   If set, this FeatureFlag may only be modified by someone with administrative rights
  #   in the specified account. The locking account must be above the target object in the
  #   account chain.
  #
  # @example_request
  #
  #   curl -X PUT 'http://<canvas>/api/v1/courses/1/features/flags/fancy_wickets' \
  #     -H "Authorization: Bearer " \
  #     -F "state=on"
  #
  # @returns FeatureFlag
  def update
    if authorized_action(@context, @current_user, :manage_feature_flags)
      return render json: { message: "must specify feature" }, status: :bad_request unless params[:feature].present?

      feature_def = Feature.definitions[params[:feature]]
      return render json: { message: "invalid feature" }, status: :bad_request unless feature_def

      # check whether the feature is locked
      current_flag = @context.lookup_feature_flag(params[:feature])
      return render json: { message: "higher account disallows setting feature flag" }, status: :forbidden if current_flag && current_flag.locked?(@context, @current_user)

      # if this is a hidden feature, require site admin privileges to create (but not update) a root account flag
      if !current_flag && feature_def.hidden?
        return render json: { message: "invalid feature" }, status: :bad_request unless @context.is_a?(Account) && @context.root_account? && Account.site_admin.grants_right?(@current_user, session, :manage_feature_flags)
      end

      # create or update flag
      new_flag = current_flag if current_flag && !current_flag.default? && current_flag.context_type == @context.class.name && current_flag.context_id == @context.id
      new_flag ||= @context.feature_flags.build

      new_flag.feature = params[:feature]
      new_flag.state = params[:state] if params.has_key?(:state)

      if params.has_key?(:locking_account_id)
        unless params[:locking_account_id].blank?
          locking_account = api_find(Account, params[:locking_account_id])
          return render json: { message: "locking account not found" }, status: :bad_request unless locking_account
          return render json: { message: "locking account access denied" }, status: :forbidden unless locking_account.grants_right?(@current_user, session, :manage_feature_flags)
        end
        new_flag.locking_account = locking_account
      end

      if new_flag.save
        render json: feature_flag_json(new_flag, @context, @current_user, session)
      else
        render json: new_flag.errors.to_json, status: :bad_request
      end
    end
  end

  # @API Remove feature flag
  #
  # Remove feature flag for a given Account, Course, or User.  (Note that the flag must
  # be defined on the Account, Course, or User directly.)  The object will then inherit
  # the feature flags from a higher account, if any exist.  If this flag was 'on' or 'off',
  # then lower-level account flags that were masked by this one will apply again.
  #
  # @example_request
  #
  #   curl -X DELETE 'http://<canvas>/api/v1/courses/1/features/flags/fancy_wickets' \
  #     -H "Authorization: Bearer "
  #
  # @returns FeatureFlag
  def delete
    if authorized_action(@context, @current_user, :manage_feature_flags)
      return render json: { message: "must specify feature" }, status: :bad_request unless params[:feature].present?
      flag = @context.feature_flags.find_by_feature!(params[:feature])
      return render json: { message: "flag is locked" }, status: :forbidden if flag.locked?(@context, @current_user)
      flag.destroy
      render json: feature_flag_json(flag, @context, @current_user, session)
    end
  end

end
