# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DataFixup::NormalizePseudonyms
  class << self
    def backfill_unique_id_normalized
      Pseudonym.where(unique_id_normalized: nil).in_batches(of: 100, strategy: :id) do |batch|
        updates = {}
        batch.pluck(:id, :unique_id, :unique_id_normalized).each do |id, unique_id, unique_id_normalized|
          next if unique_id_normalized # just in case it got set elsewhere somehow

          # invalid characters are not allowed in normalized pseudonyms.
          # during normal pseudonym creation, they'll fail, but we can't fail
          # this migration so just replace them. these pseudonyms will no
          # longer work to log in if the user tries their original characters.
          # the most common case of this is emojis that didn't exist in Unicode 3.2.
          # Note that we can't use the regular Unicode replacement character, as
          # that is not allowed in a normalized id either.
          [Net::IMAP::StringPrep::Tables::IN_A_1,
           Net::IMAP::StringPrep::Tables::IN_C_3,
           Net::IMAP::StringPrep::Tables::IN_C_4,
           Net::IMAP::StringPrep::Tables::IN_C_5,
           "\ufffd"].each do |table|
            unique_id.gsub!(table, "\u25a1")
          end
          updates[id] = Pseudonym.normalize(unique_id)
        end
        next if updates.empty?

        Pseudonym.all.update_many(updates, :unique_id_normalized)
        throttle
      end
    end

    def dedup_all
      dedup(Pseudonym.where(login_attribute: nil), :authentication_provider_id)
      dedup(Pseudonym.where.not(authentication_provider_id: nil), :authentication_provider_id, :login_attribute)
      dedup(Pseudonym.where(auth_type: [nil, "canvas", "cas", "ldap", "saml"]))
    end

    def backfill_auth_type
      Pseudonym.find_ids_in_ranges do |start_id, end_id|
        Pseudonym.where(auth_type: nil)
                 .joins(:authentication_provider)
                 .where(id: start_id..end_id)
                 .update_all("auth_type=authentication_providers.auth_type")
        throttle
      end
    end

    private

    def dedup(scope, *additional_group_by)
      scope = scope.active
      dups = scope.group(:unique_id_normalized, :account_id, *additional_group_by)
                  .having("COUNT(*) > 1")
                  .pluck(:unique_id_normalized, :account_id, *additional_group_by)
      remove_dups(scope, dups, *additional_group_by)
    end

    def remove_dups(scope, dups, *additional_group_by)
      dups.each do |unique_id_normalized, account_id, *other_fields|
        # sort SIS Pseudonyms first,
        # then prefer a pseudonym with an explicit auth provider,
        # then most recent login,
        # then pseudonyms that are already normalized (taking into account our previous rules),
        # and finally just choose the newest
        s = scope.where(unique_id_normalized:, account_id:, **additional_group_by.zip(other_fields).to_h)
        s2 = s.order(Arel.sql(<<~SQL.squish))
          sis_user_id IS NULL,
          current_login_at DESC NULLS LAST,
          authentication_provider_id IS NULL,
          lower(unique_id)<>unique_id_normalized,
          id DESC
        SQL
        s2.offset(1)
          .each do |p|
          p.unique_id = "NORMALIZATION-COLLISION-#{SecureRandom.uuid}-#{p.unique_id}"
          p.unique_id_normalized = Pseudonym.normalize(p.unique_id)
          # have to skip validation because some old pseudonyms are no longer valid
          # by current rules, and we don't want to deal with that here
          # (we also don't want to trigger additional queries in this already-long
          # DataFixup)
          p.save(validate: false)
        end
      end
    end

    def throttle
      Canvas::Reloader.reload
      sleep_interval_per_batch = Setting.get("sleep_interval_per_backfill_nulls_batch", nil).presence&.to_f
      sleep(sleep_interval_per_batch) if sleep_interval_per_batch # rubocop:disable Lint/NoSleep
    end
  end
end
