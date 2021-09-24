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

class RecreateSubscriptionsForPlagiarismTools < ActiveRecord::Migration[5.2]
  tag :postdeploy

  def up
    DataFixup::CreateSubscriptionsForPlagiarismTools.delay_if_production(strand: "plagiarism_subscription_create_#{Shard.current.id}").
      recreate_subscriptions
  end

  def down
    Delayed::Job.where(strand: "plagiarism_subscription_create_#{Shard.current.id}").destroy_all
    DataFixup::CreateSubscriptionsForPlagiarismTools.delay_if_production(strand: "plagiarism_subscription_oldversion_#{Shard.current.id}").
      delete_subscriptions
    DataFixup::CreateSubscriptionsForPlagiarismTools.delay_if_production(strand: "plagiarism_subscription_oldversion_#{Shard.current.id}").
      create_subscriptions
  end
end
