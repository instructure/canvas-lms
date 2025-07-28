# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Permissions, type: :module do
  before :all do
    @original_permission = Permissions.instance_variable_get(:@permissions)
  end

  after do
    Permissions.instance_variable_set(:@permissions, @original_permission)
  end

  before do
    Permissions.instance_variable_set(:@permissions, nil)
  end

  describe ".register" do
    it "registers permissions correctly" do
      permissions = { read: { description: "Read Permission" }, write: { description: "Write Permission" } }
      Permissions.register(permissions)
      expect(Permissions.retrieve).to eq(permissions)
    end

    it "raises an error if trying to register permissions after the hash is frozen" do
      Permissions.retrieve.freeze
      expect do
        Permissions.register(read: { description: "Read Permission" })
      end.to raise_error(RuntimeError, "Cannot register permissions after the application has been fully initialized")
    end

    it "logs a warning and skips the duplicate permission" do
      key = :read
      Permissions.register(key => { description: "Read Permission" })
      allow(Rails.logger).to receive(:warn)
      expect do
        Permissions.register(key => { description: "Duplicate Read Permission" })
      end.not_to raise_error
      expect(Rails.logger).to have_received(:warn).with("Duplicate permission detected: #{key}")
      # Ensure the duplicate permission is not added
      expect(Permissions.instance_variable_get(:@permissions)[key][:description]).to eq("Read Permission")
    end

    it "raises an error if the input is not a hash" do
      expect do
        Permissions.register(["read", "write"])
      end.to raise_error(RuntimeError, "Permissions.register must be called with a hash of permission(s)")
    end
  end

  describe ".retrieve" do
    it "returns the registered permissions" do
      permissions = { read: { description: "Read Permission" }, write: { description: "Write Permission" } }
      Permissions.register(permissions)
      expect(Permissions.retrieve).to eq(permissions)
    end

    it "returns an empty hash if no permissions are registered" do
      expect(Permissions.retrieve).to eq({})
    end

    it "freezes the permissions hash after the first call to retrieve" do
      Permissions.register(read: { description: "Read Permission" })
      Rails.application.config.after_initialize { Permissions.retrieve.freeze }
      expect(Permissions.retrieve).to be_frozen
    end
  end
end
