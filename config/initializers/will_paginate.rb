WillPaginate::Finder::ClassMethods.module_eval do
  def paginate(*args)
    options = args.pop
    page, per_page, total_entries = wp_parse_options(options)
    finder = (options[:finder] || 'find').to_s
    without_count = options[:without_count]

    if finder == 'find'
      # an array of IDs may have been given:
      total_entries ||= (Array === args.first and args.first.size)
      # :all is implicit
      args.unshift(:all) if args.empty?
    end

    WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      count_options = options.except :page, :per_page, :total_entries, :finder, :without_count
      find_options = count_options.except(:count).update(:offset => pager.offset, :limit => pager.per_page)
      find_options.update(:limit => pager.per_page + 1) if without_count

      args << find_options
      # @options_from_last_find = nil
      entries = send(finder, *args) { |*a| yield(*a) if block_given? }
      if (without_count)
        pager.total_entries = pager.offset + entries.size
        entries.slice!(pager.per_page)
      end
      pager.replace(entries)

      # magic counting for user convenience:
      pager.total_entries = wp_count(count_options, args, finder) unless pager.total_entries
    end
  end
end
