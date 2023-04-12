# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::RemoveDelicious do
  it "removes delicious when it is at the start" do
    account = account_model(allowed_services: "+delicious,-skype")
    described_class.run

    expect(account.reload.allowed_services).to eq "-skype"
  end

  it "removes delicious when it is at the end" do
    account = account_model(allowed_services: "+skype,-delicious")
    described_class.run

    expect(account.reload.allowed_services).to eq "+skype"
  end

  it "removes delicious when it is in the middle" do
    account = account_model(allowed_services: "+skype,-delicious,+diigo")
    described_class.run

    expect(account.reload.allowed_services).to eq "+skype,+diigo"
  end

  it "removes delicious when it is present multiple times" do
    account = account_model(allowed_services: "+delicious,+skype,-delicious,+diigo,+delicious")
    described_class.run

    expect(account.reload.allowed_services).to eq "+skype,+diigo"
  end

  it "deletes any configured delicious user services" do
    user_service = user_service_model(service: "delicious")
    described_class.run

    expect { user_service.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
