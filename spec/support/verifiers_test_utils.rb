# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

def double_testing_with_disable_adding_uuid_verifier_in_api_ff(attachment_variable_name: nil, &)
  describe "when disable_adding_uuid_verifier_in_api FF is true" do
    before do
      if attachment_variable_name.nil?
        if @attachment.is_a?(ActiveRecord::Relation)
          @attachment.each do |attachment|
            attachment.root_account.enable_feature!(:disable_adding_uuid_verifier_in_api)
          end
        else
          @attachment.root_account.enable_feature!(:disable_adding_uuid_verifier_in_api)
        end
      else
        instance_variable_get(:"@#{attachment_variable_name}").root_account.enable_feature!(:disable_adding_uuid_verifier_in_api)
      end
    end

    let(:disable_adding_uuid_verifier_in_api) { true }

    instance_exec(&) if block_given?
  end

  describe "when disable_adding_uuid_verifier_in_api FF is false" do
    before do
      if attachment_variable_name.nil?
        if @attachment.is_a?(ActiveRecord::Relation)
          @attachment.each do |attachment|
            attachment.root_account.disable_feature!(:disable_adding_uuid_verifier_in_api)
          end
        else
          @attachment.root_account.disable_feature!(:disable_adding_uuid_verifier_in_api)
        end
      else
        instance_variable_get(:"@#{attachment_variable_name}").root_account.disable_feature!(:disable_adding_uuid_verifier_in_api)
      end
    end

    let(:disable_adding_uuid_verifier_in_api) { false }

    instance_exec(&) if block_given?
  end
end
