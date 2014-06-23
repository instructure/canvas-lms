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

module Api::V1::AuthenticationEvent
  include Api::V1::Pseudonym
  include Api::V1::Account
  include Api::V1::User
  include Api::V1::PageView

  def authentication_event_json(event, user, session)
    links = {
      :login => Shard.relative_id_for(event.pseudonym_id, Shard.current, Shard.current),
      :account => Shard.relative_id_for(event.account_id, Shard.current, Shard.current),
      :user => Shard.relative_id_for(event.user_id, Shard.current, Shard.current),
      :page_view => PageView.find_by_id(event.request_id).try(:id)
    }

    {
      :id => event.id,
      :created_at => event.created_at.in_time_zone,
      :event_type => event.event_type,
      :links => links
    }
  end

  def authentication_events_json(events, user, session)
    events.map{ |event| authentication_event_json(event, user, session) }
  end

  def authentication_events_compound_json(events, user, session)
    {
      links: links_json,
      events: authentication_events_json(events, user, session),
      linked: linked_json(events, user, session)
    }
  end

  private

  def links_json
    # This should include logins, users, and page_views.  There is no end point
    # for returning single json objects for those models.
    {
      "events.login" => nil,
      "events.account" => templated_url(:api_v1_account_url, "{events.account}"),
      "events.user" => nil,
      "events.page_view" => nil
    }
  end

  def linked_json(events, user, session)
    pseudonyms = []
    accounts = []
    pseudonym_ids = events.map{ |event| event.pseudonym_id }.uniq
    Shard.partition_by_shard(pseudonym_ids) do |shard_pseudonym_ids|
      shard_pseudonyms = Pseudonym.where(:id => shard_pseudonym_ids).all
      account_ids = shard_pseudonyms.map{ |pseudonym| pseudonym.account_id }.uniq
      accounts.concat Account.where(:id => account_ids).all
      pseudonyms.concat shard_pseudonyms
    end

    user_ids = events.map{ |event| event.user_id }.uniq
    users = Shard.partition_by_shard(user_ids) do |shard_user_ids|
      User.where(:id => shard_user_ids).all
    end

    page_view_ids = events.map{ |event| event.request_id }
    page_views = PageView.find_all_by_id(page_view_ids) if page_view_ids.length > 0
    page_views ||= []

    {
      logins: pseudonyms_json(pseudonyms, user, session),
      accounts: accounts_json(accounts, user, session, []),
      users: users_json(users, user, session, [], @domain_root_account),
      page_views: page_views_json(page_views, user, session)
    }
  end
end
