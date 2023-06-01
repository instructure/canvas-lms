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

module Rake
  # An API for running a large number of Rake tasks that may have dependencies
  # between them. The graph resolves the dependencies, orders the tasks and
  # partitions them in arrays, allowing you to run each batch in parallel
  # or all tasks serially.
  #
  # The API tries to stay as close to Rake's as possible.
  #
  # == Usage
  #
  #     batches = Rake::TaskGraph.draw do
  #       task 'a' => []
  #       task 'b' => ['a']
  #       task 'c' => []
  #       task 'd' => ['c','b']
  #     end
  #     # => [ ['a','c'], ['b'], ['d'] ]
  #
  #     # run all tasks in a batch in parallel:
  #     batches.each do |tasks|
  #       Parallel.each(tasks) { |name| Rake::Task[name].invoke }
  #     end
  #
  #     # or, run all tasks serially and in the right order:
  #     batches.flatten.each do |task|
  #       Rake::Task[task].invoke
  #     end
  #
  # == Options
  #
  # You can transform a "node", which is a string by default, into a different
  # value by passing a block that the graph will yield to when it's time to
  # insert the node into a batch:
  #
  #     TaskGraph.draw do
  #       task 'a' do
  #         5
  #       end
  #     end.to_a
  #     # => [ 5 ]
  #
  class TaskGraph
    IDENTITY = ->(x) { x }

    attr_reader :nodes, :transformers

    def self.draw(&)
      new.tap { |x| x.instance_exec(&) }.batches
    end

    def initialize
      @nodes = {}
      @transformers = {}
    end

    def task(name_and_deps, &transformer)
      name, deps = if name_and_deps.is_a?(Hash)
                     name_and_deps.first
                   else
                     [name_and_deps, []]
                   end

      @nodes[name] = deps
      @transformers[name] = transformer || IDENTITY
    end

    def batches
      ensure_all_nodes_are_defined!

      to_take = nodes.keys

      [].tap do |batches|
        to_take.size.times do # cap iterations just in case
          batch = to_take.reduce([]) do |acc, node|
            take_or_resolve(node, acc, to_take)
          end

          if batch.empty?
            break # we're done
          else
            to_take -= batch
            batches << batch.map { |x| @transformers[x][x] }
          end
        end
      end
    end

    private

    def ensure_all_nodes_are_defined!
      undefined = nodes.reduce([]) do |errors, (_node, deps)|
        errors + deps.reject { |dep| nodes.key?(dep) }
      end

      if undefined.any?
        raise <<~TEXT

          The following nodes are listed as dependents but were not defined:

            - #{undefined.uniq.join("\n  - ")}

        TEXT
      end
    end

    def take_or_resolve(node, batch, to_take, visited = [])
      if visited.include?(node)
        raise "node \"#{node}\" has a self or circular dependency"
      end

      # don't dupe if we already took it this pass (e.g. as a dep):
      if batch.include?(node)
        return batch
      end

      unresolved_deps = to_take & nodes[node]

      # assign to this batch if all deps are satisfied:
      if unresolved_deps.empty?
        return batch.push(node)
      end

      # try to resolve as many of the deps as possible in this pass and retry
      # ourselves in the next:
      unresolved_deps.reduce(batch) do |acc, dep|
        # take_or_resolve(dep, acc, to_take, visited.push(node))
        take_or_resolve(dep, acc, to_take, visited + [node])
      end
    end
  end
end
