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
#

module ConditionalRelease
  module Assimilator
    def self.run(root_account)
      # you will be assimilated into the monolith
      # resistance is futile

      raise "not a root account" unless root_account.root_account? # sanity checks
      raise "already enabled natively" if ConditionalRelease::Service.natively_enabled_for_account?(root_account)

      root_account.settings[:conditional_release_assimilation_started_at] ||= Time.now.utc
      root_account.settings.delete(:conditional_release_assimilation_failed_at)
      root_account.save!

      rules_data = retrieve_rules_data_from_service(root_account)
      trigger_assignment_ids = []
      rules_data.each_slice(200) do |batched_rules|
        all_assignment_ids = batched_rules.map{|r| r["trigger_assignment"]} +
          batched_rules.map{|r| r["scoring_ranges"].map{|s| s["assignment_sets"].map{|as| as["assignments"].map{|a| a["assignment_id"]}}}}.flatten
        prefetched_assignments = Assignment.active.where(:id => all_assignment_ids).index_by(&:id)
        batched_rules.each do |rule_hash|
          course_id = rule_hash["course_id"].to_i
          trigger_assignment = prefetched_assignments[rule_hash["trigger_assignment"].to_i]
          next unless trigger_assignment && trigger_assignment.context_id == course_id && trigger_assignment.root_account_id == root_account.id
          trigger_assignment_ids << trigger_assignment.id

          rule = trigger_assignment.conditional_release_rules.new(:course_id => course_id, :root_account_id => trigger_assignment.root_account_id)
          ranges = rule_hash['scoring_ranges'].map do |range_hash|
            range_hash.except!('id', 'rule_id') # don't save these
            range_hash["assignment_sets_attributes"] = range_hash.delete("assignment_sets").map do |set_hash|
              set_hash['service_id'] = set_hash.delete('id') # hold onto the old id as a instance variable
              set_hash.delete('scoring_range_id')
              associations = []
              set_hash.delete('assignments').each do |assoc_hash|
                released_assignment = prefetched_assignments[assoc_hash["assignment_id"].to_i]
                next unless released_assignment && released_assignment.context_id == course_id
                associations << {'assignment_id' => released_assignment.id}.merge(assoc_hash.slice('created_at', 'updated_at'))
              end
              set_hash["assignment_set_associations_attributes"] = associations
              set_hash
            end
            range_hash
          end
          if rule.update(scoring_ranges_attributes: ranges)
            service_to_native_set_id_map = {}
            rule.scoring_ranges.each{|range| range.assignment_sets.each{|set| service_to_native_set_id_map[set.service_id] = set.id}}
            assignment_set_inserts = []
            rule_hash['assignment_set_actions'].each do |action_hash|
              native_set_id = service_to_native_set_id_map[action_hash.delete('assignment_set_id')]
              next unless native_set_id
              action_hash['assignment_set_id'] = native_set_id
              action_hash['root_account_id'] = rule.root_account_id
              action_hash.delete('id')
              ['student_id', 'actor_id'].each{|k| action_hash[k] = action_hash[k].to_i}
              assignment_set_inserts << action_hash
            end
            assignment_set_inserts.each_slice(1000) do |sliced_inserts|
              ConditionalRelease::AssignmentSetAction.bulk_insert(sliced_inserts)
            end
          else
            ::Rails.logger.warn("Rule #{rule_hash["id"]} from service for account #{root_account.global_id} could not be migrated: #{rule.errors.full_messages}")
          end
        end
      end

      root_account.reload
      root_account.settings[:conditional_release_assimilation_ended_at] = Time.now.utc
      root_account.settings[:use_native_conditional_release] = true
      root_account.save!

      # resync submissions that may have been graded in the meantime
      trigger_assignment_ids.each_slice(50) do |sliced_assignment_ids|
        Submission.where(:assignment_id => sliced_assignment_ids).
          where("updated_at > ?", root_account.settings[:conditional_release_assimilation_started_at]).
          find_each(&:queue_conditional_release_grade_change_handler)
      end
    rescue
      ::Rails.logger.error("Conditional Release assimilation failed for account #{root_account.global_id}: #{$!.message}")
      root_account.reload
      root_account.settings[:conditional_release_assimilation_failed_at] = Time.now.utc
      root_account.save!
      raise
    end

    def self.retrieve_rules_data_from_service(root_account)
      user = Pseudonym.active.where(account_id: root_account.id, unique_id: ConditionalRelease::Service.unique_id).first&.user
      raise "can't find Conditional Release API user for root account: #{root_account.id}" unless user

      jwt = ConditionalRelease::Service.jwt_for(root_account, user, root_account.domain)
      start_request = CanvasHttp.post(ConditionalRelease::Service.start_export_url, {"Authorization" => "Bearer #{jwt}"})
      raise "could not start export on service-side" unless start_request.code == '200'

      sleep 5 # give the service a little time to process before we start hitting it - most should finish quickly

      waiting_for_export = true
      retry_count = 0
      while waiting_for_export
        jwt = ConditionalRelease::Service.jwt_for(root_account, user, root_account.domain)
        status_request = CanvasHttp.get(ConditionalRelease::Service.export_status_url, {"Authorization" => "Bearer #{jwt}"})
        raise "could not retrieve export status" unless status_request.code == '200'
        body = JSON.parse(status_request.body)
        raise "export failed on service side" if body['migration_failed']
        if body['migrated']
          waiting_for_export = false
        else
          retry_count += 1
          raise "giving up waiting for service export" if retry_count > 30 # if we've been waiting for 15 min something probably went wrong
          sleep 30 # okay this is probably a big shard - let's wait
        end
      end

      jwt = ConditionalRelease::Service.jwt_for(root_account, user, root_account.domain)
      download_request = CanvasHttp.get(ConditionalRelease::Service.download_export_url, {"Authorization" => "Bearer #{jwt}"})
      raise "could not retrieve export status" unless download_request.code == '200'
      JSON.parse(Zlib::Inflate.inflate(download_request.body))
    end

    def self.assimilation_in_progress?(root_account)
      !!root_account.settings[:conditional_release_assimilation_started_at] &&
        !(root_account.settings[:conditional_release_assimilation_ended_at] || root_account.settings[:conditional_release_assimilation_failed_at])
    end
  end
end
