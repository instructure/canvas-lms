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

          updates[id] = normalize(unique_id)
        end
        next if updates.empty?

        Pseudonym.all.update_many(updates, :unique_id_normalized)
        throttle
      end
    end

    def dedup_all
      relink_canvas_auth_provider
      dedup(Pseudonym.where(login_attribute: nil), :authentication_provider_id)
      dedup(Pseudonym.where.not(authentication_provider_id: nil), :authentication_provider_id, :login_attribute)
      %w[canvas cas ldap saml].each do |auth_type|
        dedup_special(auth_type)
      end
      dedup(Pseudonym.where(authentication_provider_id: nil))
    end

    private

    def dedup(scope, *additional_group_by)
      scope = scope.active
      dups = scope.group(:unique_id_normalized, :account_id, *additional_group_by)
                  .having("COUNT(*) > 1")
                  .pluck(:unique_id_normalized, :account_id, *additional_group_by)
      remove_dups(dups) do |unique_id_normalized, account_id, *other_fields|
        scope.where(unique_id_normalized:, account_id:, **additional_group_by.zip(other_fields).to_h)
      end
    end

    def dedup_special(auth_type)
      dups = Pseudonym.active
                      .joins(:authentication_provider)
                      .where(authentication_providers: { auth_type: })
                      .joins(<<~SQL.squish)
                        INNER JOIN #{Pseudonym.quoted_table_name} p2
                          ON p2.unique_id_normalized = pseudonyms.unique_id_normalized
                            AND p2.account_id = pseudonyms.account_id
                            AND p2.authentication_provider_id IS NULL
                            AND p2.workflow_state <> 'deleted'
                      SQL
                      .pluck("pseudonyms.id, p2.id AS p2_id")
      remove_dups(dups) do |ids|
        Pseudonym.where(id: ids)
      end
    end

    def remove_dups(dups)
      dups.each do |dup|
        # sort SIS Pseudonyms first,
        # then prefer a pseudonym with an explicit auth provider,
        # then most recent login,
        # then pseudonyms that are already normalized (taking into account our previous rules),
        # and finally just choose the newest
        (yield dup).order(Arel.sql(<<~SQL.squish))
          sis_user_id IS NULL,
          current_login_at DESC NULLS LAST,
          authentication_provider_id IS NULL,
          password_auto_generated,
          lower(unique_id)<>unique_id_normalized,
          id DESC
        SQL
                   .offset(1)
                   .pluck(:id, :unique_id).each do |id, unique_id|
          unique_id = "NORMALIZATION-COLLISION-#{SecureRandom.uuid}-#{unique_id}"
          unique_id_normalized = normalize(unique_id)
          Pseudonym.where(id:).update_all(unique_id:, unique_id_normalized:, updated_at: Time.zone.now)
        end
      end
    end

    # If a non-associated pseudonym that has been used, and has a non-auto-generated password
    # conflicts with a pseudonym associated with CAS, LDAP, or SAML (that has an auto-generated
    # password), and doesn't _also_ conflict with a pseudonym associated with Canvas auth, move
    # the pseudonym to Canvas auth, so that it won't count as a conflict between CAS/LDAP/SAML and
    # NULL later.
    def relink_canvas_auth_provider
      already_moved = Set.new
      Pseudonym.active
               .joins(<<~SQL.squish)
                 INNER JOIN #{Pseudonym.quoted_table_name} p2
                   ON pseudonyms.unique_id_normalized = p2.unique_id_normalized
                     AND pseudonyms.account_id = p2.account_id
                     AND p2.authentication_provider_id IS NOT NULL
                 INNER JOIN #{AuthenticationProvider.quoted_table_name}
                   ON authentication_providers.id = p2.authentication_provider_id
               SQL
               .where(authentication_provider_id: nil,
                      password_auto_generated: false,
                      authentication_providers: { auth_type: %w[cas ldap saml] })
               .where(<<~SQL.squish)
                 p2.workflow_state <> 'deleted'
                 AND NOT EXISTS (
                   SELECT 1 FROM #{Pseudonym.quoted_table_name} p3
                   INNER JOIN #{AuthenticationProvider.quoted_table_name} ap2
                     ON p3.authentication_provider_id=ap2.id
                   WHERE
                     p3.account_id=pseudonyms.account_id
                     AND p3.unique_id_normalized = pseudonyms.unique_id_normalized
                     AND p3.workflow_state <> 'deleted'
                     AND ap2.auth_type = 'canvas'
                 )
               SQL
               .preload(:account)
               .find_each(strategy: :id) do |p|
        next if already_moved.include?(p.id)

        conflict_set = Pseudonym.active
                                .where(account_id: p.account_id,
                                       unique_id_normalized: p.unique_id_normalized,
                                       authentication_provider_id: nil)
                                .order(Arel.sql(<<~SQL.squish))
                                  sis_user_id IS NULL,
                                  password_auto_generated,
                                  current_login_at DESC NULLS LAST,
                                  unique_id<>unique_id_normalized, id DESC
                                SQL
                                .pluck(:id, :unique_id)
        if conflict_set.size > 1
          to_leave_alone = conflict_set.shift

          updates = {}
          conflict_set.each do |id, unique_id|
            unique_id = "NORMALIZATION-COLLISION-#{SecureRandom.uuid}-#{unique_id}"
            unique_id_normalized = normalize(unique_id)
            updates[id] = [unique_id, unique_id_normalized]
          end
          already_moved.merge(updates.keys)

          Pseudonym.all.update_many(updates, :unique_id, :unique_id_normalized)

          # we should still see the one we left alone in a later iteration
          next unless to_leave_alone.first == p.id
        end
        p.authentication_provider = p.account.canvas_authentication_provider
        p.save(validate: false)
      end
    end

    def throttle
      Canvas::Reloader.reload
      sleep_interval_per_batch = Setting.get("sleep_interval_per_backfill_nulls_batch", nil).presence&.to_f
      sleep(sleep_interval_per_batch) if sleep_interval_per_batch # rubocop:disable Lint/NoSleep
    end

    def normalize(unique_id)
      unique_id = unique_id.dup
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
      Pseudonym.normalize(unique_id)
    end
  end
end
