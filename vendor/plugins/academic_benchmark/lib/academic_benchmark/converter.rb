module AcademicBenchmark
  class Converter < Canvas::Migration::Migrator
    COMMON_CORE_GUID = 'A83297F2-901A-11DF-A622-0C319DFF4B22'

    def initialize(settings={})
      super(settings, "academic_benchmark")

      ab_settings = AcademicBenchmark.config

      @api_key = settings[:api_key] || ab_settings[:api_key]
      @api = AcademicBenchmark::Api.new(@api_key, :base_url => settings[:base_url] || ab_settings[:api_url])

      @common_core_guid = settings[:common_core_guid] || ab_settings[:common_core_guid].presence
      @course[:learning_outcomes] = []
    end

    def export
      if content_migration && !Account.site_admin.grants_right?(content_migration.user, :manage_global_outcomes)
        raise Canvas::Migration::Error.new("User isn't allowed to edit global outcomes")
      end

      if @archive_file
        convert_file
      elsif @settings[:authorities] || @settings[:guids] || @settings[:refresh_all_standards]
        if @api_key
          if @settings[:refresh_all_standards]
            refresh_all_outcomes
          else
            convert_authorities(@settings[:authorities]) if @settings[:authorities]
            convert_guids(@settings[:guids]) if @settings[:guids]
          end
        else
          message = I18n.t('academic_benchmark.no_api_key', "An API key is required to use Academic Benchmarks")
          add_warning(message)
          raise Canvas::Migration::Error.new("no academic benchmarks api key")
        end
      else
        message = I18n.t('academic_benchmark.no_file', "No outcome file or authority given")
        add_warning(message)
        raise Canvas::Migration::Error.new("No outcome file or authority given")
      end

      save_to_file
      @course
    end

    def convert_file
      data = @api.parse_ab_data(@archive_file.read)
      process_json_data(data)
    rescue APIError
      add_warning(I18n.t("academic_benchmark.bad_ab_file", "The provided Academic Benchmark file has an error."), $!)
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
      # todo update to incrementally get data from api
      res = @api.browse({:levels => 0}.merge(opts))
      process_json_data(res)
    rescue EOFError, APIError
      add_warning(I18n.t("academic_benchmark.api_error", "Couldn't update standards for authority %{auth}.", :auth => opts[:authority] || opts[:guid]), $!)
    end

    # Get list of all authorities available for this api key and refresh them
    def refresh_all_outcomes
      auths = @api.list_available_authorities
      auth_count = auths.length
      set_progress(2)
      auths.each_with_index do |auth, i|
        next unless auth["type"] == "authority"

        refresh_outcomes(:guid => auth["guid"])
        set_progress((i/auth_count.to_f) * 90)
      end

      set_progress(95)
    rescue APIError
      add_warning(I18n.t("academic_benchmark.bad_response_all", "Couldn't update the standards."), $!)
    end

    def process_json_data(data)
      if data = find_authority(data)
        outcomes = Standard.new(data).build_outcomes
        @course[:learning_outcomes] << outcomes
      else
        add_warning(I18n.t("academic_benchmark.no_authority", "Couldn't find an authority to update"))
      end
    end

    def find_authority(data)
      return nil unless data
      if data.is_a? Array
        return find_authority(data.first)
      elsif data.is_a? Hash
        if data["type"] && data["type"] == 'authority'
          return data
        elsif data["itm"]
          return find_authority(data["itm"].first)
        end
      end

      nil
    end
  end
end