class ParallelizedSpecs
  class Grouper
    def self.in_groups(items, num_groups)
      groups = Array.new(num_groups){ [] }

      until items.empty?
        num_groups.times do |group_number|
          groups[group_number] << items.shift
        end
      end

      groups.map!(&:sort!)
    end

    def self.in_even_groups_by_size(items_with_sizes, num_groups, options)
      groups = Array.new(num_groups){{:items => [], :size => 0}}
      # add all files that should run in a single process to one group
      (options[:single_process]||[]).each do |pattern|
        matched, items_with_sizes = items_with_sizes.partition{|item, size| item =~ pattern }
        smallest = smallest_group(groups)
        matched.each{|item,size| add_to_group(smallest, item, size) }
      end

      # add all other files
      largest_first(items_with_sizes).each do |item, size|
        smallest = smallest_group(groups)
        add_to_group(smallest, item, size)
      end

      groups.map!{|g| g[:items].sort }
    end

    def self.largest_first(files)
      files.sort_by{|item, size| size }.reverse
    end

  private

    def self.smallest_group(groups)
      groups.min_by{|g| g[:size] }
    end

    def self.add_to_group(group, item, size)
      group[:items] << item
      group[:size] += size
    end
  end
end
