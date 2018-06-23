#
# Copyright (C) 2016 - present Instructure, Inc.
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

module SIS
  class UserObserverImporter < BaseImporter

    def process
      start = Time.zone.now
      importer = Work.new(@batch, @root_account, @logger)

      Enrollment.skip_touch_callbacks(:course) do
        Enrollment.suspend_callbacks(:set_update_cached_due_dates) do
          User.skip_updating_account_associations do
            yield importer
          end
        end
      end

      importer.user_observers_to_update_sis_batch_ids.in_groups_of(1000, false) do |batch|
        UserObservationLink.where(id: batch).update_all(sis_batch_id: @batch.id)
      end

      User.update_account_associations(importer.users_to_update_account_associations.to_a)

      @logger.debug("User Observers took #{Time.zone.now - start} seconds")

      importer.success_count
    end

    class Work
      attr_accessor :success_count, :users_to_update_account_associations,
                    :user_observers_to_update_sis_batch_ids

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0

        @users_to_update_account_associations = Set.new
        @user_observers_to_update_sis_batch_ids = []
      end

      def process_user_observer(observer_id, student_id, status)
        @logger.debug("Processing user_observer #{[observer_id, student_id, status].inspect}")

        raise ImportError, "No observer_id given for a user observer" if observer_id.blank?
        raise ImportError, "No user_id given for a user observer" if student_id.blank?
        raise ImportError, "Can't observe yourself user #{student_id}" if student_id == observer_id
        raise ImportError, "Improper status \"#{status}\" for a user_observer" unless status =~ /\A(active|deleted)\z/i
        return if @batch.skip_deletes? && status =~ /deleted/i

        o_pseudo = @root_account.pseudonyms.active.where(sis_user_id: observer_id).take
        raise ImportError, "An observer referenced a non-existent user #{observer_id}" unless o_pseudo

        s_pseudo = @root_account.pseudonyms.active.where(sis_user_id: student_id).take
        raise ImportError, "A student referenced a non-existent user #{student_id}" unless s_pseudo

        observer = o_pseudo.user
        student = s_pseudo.user
        raise ImportError, "Can't observe yourself user #{student_id}" if observer == student

        add_remove_observer(observer, student, observer_id, student_id, status)
      end

      def add_remove_observer(observer, student, observer_id, student_id, status)
        case status.downcase
        when 'active'
          user_observer = UserObservationLink.create_or_restore(observer: observer, student: student, root_account: @root_account)
        when 'deleted'
          user_observer = observer.as_observer_observation_links.for_root_accounts(@root_account).where(user_id: student).take
          if user_observer
            user_observer.destroy
          else
            raise ImportError, "Can't delete a non-existent observer for observer: #{observer_id}, student: #{student_id}"
          end
        end
        raise ImportError, "Failed to return user observer for observer: #{observer_id}, student: #{student_id}" unless user_observer
        @users_to_update_account_associations.add observer.id
        @user_observers_to_update_sis_batch_ids << user_observer.id
        @success_count += 1
      end

    end
  end
end
