#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'httparty'

module AcademicBenchmark

class CliTools

  def self.whitelisted_ips
    HTTParty.get("#{api_url}maintainAccess?api_key=#{api_key}")
  end

  def self.whitelist_ip(ip, note)
    HTTParty.get(
      "#{api_url}maintainAccess?api_key=#{api_key}&op=add&addr=#{ip}&note=#{note}"
    )
  end

  def self.remove_from_whitelist(ip)
    if self.is_ip_address(ip)
      self.remove_ip_from_whitelist(ip)
    else
      self.remove_note_from_whitelist(ip)
    end
  end

  def self.remove_ip_from_whitelist(ip)
    HTTParty.get(
      "#{api_url}maintainAccess?api_key=#{api_key}&op=remove&addr=#{ip}"
    )
  end

  def self.remove_note_from_whitelist(note)
    ips = self.whitelisted_ips

    if ips["ab_rsp"] && ips["ab_rsp"]["access"]
      ips["ab_rsp"]["access"].each do |entry|
        return remove_ip_from_whitelist(entry["addr"]) if entry["note"] == note
      end
      puts "There were no whitelisted IP addresses with a note matching '#{note}'"
    else
      puts "Error retrieving list of whitelisted IP addresses: #{ips.to_json}"
    end
  end

  def self.whitelisted?(ip)
    ips = whitelisted_ips
    ips["ab_rsp"] && ips["ab_rsp"]["access"].any?{ |i| i["addr"] == ip }
  end

  def self.delete_imported_outcomes(parent_group_title, no_prompt: false, override_shard_restriction: false)
    unless no_prompt
      return unless warn_shard
      return unless warn_deleting(parent_group_title)
    end
    Rails.logger.warn("AcademicBenchmark::CliTools - deleting outcomes under #{parent_group_title}")
    delete_with_children(LearningOutcomeGroup.where(title: parent_group_title).first)
    Rails.logger.warn("AcademicBenchmark::CliTools - finished deleting outcomes under #{parent_group_title}")
  end

  # Make sure this account is on its own shard
  # If it is not, then we could affect other schools
  def self.own_shard
    Account.root_accounts.count <= 1
  end

  private
  def self.warn_deleting(title)
    print "WARNING:  You are about to delete all imported outcomes under #{title} for this shard.  Proceed?  (Y/N): "
    return false unless STDIN.gets.chomp.downcase == "y"
    return true
  end

  private
  def self.warn_shard
    unless own_shard
      print "WARNING:  This shard has more than one account on it!  This means you will affect multiple customers with your actions.  Proceed?  (Y/N): "
      return false unless STDIN.gets.chomp.downcase == "y"
    end
    true
  end

  private
  def self.delete_with_children(item, no_prompt: false, override_shard_restriction: false)
    expected_types = [LearningOutcomeGroup, ContentTag]
    if !no_prompt && !expected_types.include?(item.class)
      puts "Expected #{expected_types.map{|t| t.to_s}.join(" or ") } but received a '#{item.class.to_s}'"
      return
    end

    if item.is_a?(LearningOutcomeGroup)
      # These two queries can be combined when we hit rails 4
      # and have multi-column pluck
      child_outcome_links = ContentTag.where(
        tag_type: 'learning_outcome_association',
        content_type: 'LearningOutcome',
        context_id: item.id
      ).pluck(:id)
      child_outcome_ids = ContentTag.where(
        tag_type: 'learning_outcome_association',
        content_type: 'LearningOutcome',
        context_id: item.id
      ).pluck(:content_id)

      # delete all links to our children
      ContentTag.destroy(child_outcome_links)
      # delete all of our children
      LearningOutcome.destroy(child_outcome_ids)

      item.child_outcome_groups.each do |child|
        delete_with_children(child)
      end
      item.destroy_permanently!
    else
      item.destroy_permanently!
    end
  end

  private
  def self.api_key
    AcademicBenchmark.config["api_key"]
  end

  private
  def self.api_url
    AcademicBenchmark.config["api_url"]
  end

  private
  def self.is_ip_address(ip)
    # this simple and brief regex matches IP addresses strictly
    ip =~ %r{\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b}
  end

end # class CliTools

end # module AcademicBenchmark
