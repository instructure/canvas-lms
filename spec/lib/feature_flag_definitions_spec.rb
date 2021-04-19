# frozen_string_literal: true

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
#

require "spec_helper"

describe "feature_flag_definition_spec" do
  Feature.definitions.each_key do |feature_name|
    it "#{feature_name} should have a display_name and description lambdas" do
      feature = Feature.definitions[feature_name]
      expect(feature).to_not be_nil
      expect(feature.display_name.call).to_not be_nil
      expect(feature.description.call).to_not be_nil
    end
  end

  FeatureFlags::Loader.load_yaml_files.each do |name, definition|
    [:custom_transition_proc, :after_state_change_proc, :visible_on].each do |hook|
      if definition[hook]
        hook_name = definition[hook]
        it "#{name} hook for #{hook} (#{hook_name}) should exist in FeatureFlags::Hooks as a static method" do
          expect(FeatureFlags::Hooks.respond_to?(hook_name)).to be true
        end
      end
    end
  end
end
