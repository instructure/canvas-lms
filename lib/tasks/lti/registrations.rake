# frozen_string_literal: true

require "csv"

namespace :lti do
  desc <<~TEXT
    Audit LTI registrations for mismatches between account binding state and
    local registration workflow state.

    Usage:
      bundle exec rake lti:local_vs_binding_diffs
      bundle exec rake "lti:local_vs_binding_diffs[output.csv]"

    With no argument, CSV is printed to stdout.
    With a filename argument, CSV is written to that file.
  TEXT
  task :local_vs_binding_diffs, [:output_file] => :environment do |_task, args|
    mismatches = []

    # Find all non-deleted local registrations (those copied from a template)
    GuardRail.activate(:report) do
      Shard.with_each_shard(Shard.in_current_region) do
        Lti::Registration.active
                         .where.not(template_registration_id: nil)
                         .preload(:account, :template_registration)
                         .find_each do |local_reg|
          account = local_reg.account
          template_reg = local_reg.template_registration

          binding = template_reg.account_binding_for(account)
          binding_enabled = binding&.workflow_state == "on"

          local_enabled = local_reg.workflow_state == "active"

          next if binding_enabled == local_enabled

          mismatches << {
            account_id: account.global_id,
            account_name: account.name,
            template_registration_id: template_reg.global_id,
            template_registration_name: template_reg.name,
            local_registration_id: local_reg.global_id,
            local_registration_name: local_reg.name,
            binding_state: binding&.workflow_state || "none",
            local_reg_state: local_reg.workflow_state
          }
        end
      end
    end

    if mismatches.empty?
      puts "No mismatches found between account bindings and local registration states."
    else
      puts "Found #{mismatches.count} mismatches between account binding and local registration state."

      if args[:output_file]
        CSV.open(args[:output_file], "w") do |csv|
          csv << mismatches.first.keys.map(&:to_s)
          mismatches.each { |m| csv << m.values }
        end
        puts "\nResults written to #{args[:output_file]}"
      else
        puts(CSV.generate do |csv|
          csv << mismatches.first.keys.map(&:to_s)
          mismatches.each { |m| csv << m.values }
        end)
      end
    end
  end
end
