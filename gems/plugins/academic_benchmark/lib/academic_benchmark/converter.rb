module AcademicBenchmark
  class Converter < Canvas::Migration::Migrator
    COMMON_CORE_GUID = 'A83297F2-901A-11DF-A622-0C319DFF4B22'
    DEFAULT_DEPTH = 3

    def initialize(settings={})
      super(settings, "academic_benchmark")
      @ratings_overrides = settings[:migration_options] || {}

      ab_settings = AcademicBenchmark.config

      @api_key = settings[:api_key] || ab_settings[:api_key]
      @api = AcademicBenchmark::Api.new(@api_key, :base_url => settings[:base_url] || ab_settings[:api_url])

      @common_core_guid = settings[:common_core_guid] || ab_settings[:common_core_guid].presence
      @course[:learning_outcomes] = []
    end

    def export
      if content_migration && !Account.site_admin.grants_right?(content_migration.user, :manage_global_outcomes)
        raise Canvas::Migration::Error.new(I18n.t('academic_benchmark.no_perms', "User isn't allowed to edit global outcomes"))
      end

      if @archive_file
        convert_file
      elsif @settings[:authorities] || @settings[:guids]
        if @api_key && !@api_key.empty?
          convert_authorities(@settings[:authorities]) if @settings[:authorities]
          convert_guids(@settings[:guids]) if @settings[:guids]
        else
          raise Canvas::Migration::Error.new(I18n.t('academic_benchmark.no_api_key', "An API key is required to use Academic Benchmarks"))
        end
      else
        raise Canvas::Migration::Error.new(I18n.t('academic_benchmark.no_file', "No outcome file or authority given"))
      end

      save_to_file
      @course
    end

    def post_process
      if importing_common_core?
        AcademicBenchmark.set_common_core_setting!
      end
    end

    def importing_common_core?
      (@settings[:guids] && @settings[:guids].member?(AcademicBenchmark.config[:common_core_guid])) ||
              (@settings[:authorities] && @settings[:authorities].member?("CC"))
    end

    def convert_file
      data = @api.parse_ab_data(@archive_file.read)
      process_json_data(data)
    rescue APIError => e
      add_error(
        I18n.t("The provided Academic Benchmark file has an error"),
        {
          exception: e,
          error_message: e.message
        }
      )
    end

    def convert_authorities(authorities=[])
      authorities.each do |auth|
        refresh_outcomes(:authority => auth)
      end
    end

    def convert_guids(guids=[])
      guids.each do |guid|
        refresh_outcomes(:guid => guid)
      end
    end

    def refresh_outcomes(opts)
      res = build_full_auth_hash(opts)
      process_json_data(res)
    rescue EOFError, APIError => e
      add_error(
        I18n.t(
          "Couldn't update standards for authority %{auth}",
          :auth => opts[:authority] || opts[:guid]
        ),
        {
          exception: e,
          error_message: e.message
        }
      )
    end

    # get a shallow tree for the authority then process the leaves
    def build_full_auth_hash(opts)
      data = @api.browse({:levels => DEFAULT_DEPTH}.merge(opts))
      process_leaves!(find_by_prop(data, "type", "authority"))
    end

    # recursively find leaf nodes with children available to fetch
    # fetch the children and then process them
    def process_leaves!(data)
      if data.is_a? Array
        data.each do |itm|
          process_leaves!(itm)
        end
      elsif data.is_a? Hash
        if data["itm"]
          data["itm"].each do |itm|
            process_leaves!(itm)
          end
        elsif data["chld"]
          count = data.delete("chld").to_i
          if count > 0
            data.delete("chld")
            children_tree = @api.browse({:levels => DEFAULT_DEPTH, :guid => data["guid"]})
            dup_with_children = find_by_prop(children_tree, "guid", data["guid"])
            if data["guid"] == dup_with_children["guid"]
              data["itm"] = dup_with_children["itm"]
              process_leaves!(data)
            end
          end
        end
      end

      data
    end

    def process_json_data(data)
      if data = find_by_prop(data, "type", "authority")
        outcomes = Standard.new(data).build_outcomes(@ratings_overrides)
        @course[:learning_outcomes] << outcomes
      else
        err_msg = I18n.t("Couldn't find an authority to update")
        add_error(
          err_msg, { exception: nil, error_message: err_msg }
        )
      end
    end

    def find_by_prop(data, prop, value)
      return nil unless data
      if data.is_a? Array
        data.each do |itm|
          if found = find_by_prop(itm, prop, value)
            return found
          end
        end
      elsif data.is_a? Hash
        if data[prop] && data[prop] == value
          return data
        elsif data["itm"]
          return find_by_prop(data["itm"], prop, value)
        end
      end

      nil
    end

  end
end
