module AcademicBenchmark

  API_BASE_URL = "http://labs.statestandards.com/services/rest/"
  BROWSE_URL = "browse"
  SEARCH_URL = "search"
  BASE_QUERY_STRING = "?levels=0&format=json&api_key=%s"
  AUTHORITY_QUERY_STRING = BASE_QUERY_STRING + "&authority=%s"
  GUID_QUERY_STRING = BASE_QUERY_STRING + "&guid=%s"
  LIST_AUTHORITIES_QUERY_STRING = "?levels=2&format=json&api_key=%s"
  
  TITLE_MAX_LENGTH = 50

  class Converter < Canvas::Migration::Migrator
    def initialize(settings={})
      super(settings, "academic_benchmark")

      plugin = Canvas::Plugin.find('academic_benchmark_importer')

      @api_key = settings[:api_key] || (plugin && plugin.settings[:api_key])
      @root_group = settings[:root_group] || LearningOutcomeGroup.global_root_outcome_group
      @base_url = settings[:base_url] || (plugin && plugin.settings[:api_url]) || API_BASE_URL
      @browse_url = @base_url + BROWSE_URL
      @search_url = @base_url + SEARCH_URL
      @course[:learning_outcomes] = []
      @authorities = settings[:authorities]
    end

    def export
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
      json_string = @archive_file.read
      process_json_string(json_string)
    end

    def convert_authorities(authorities=[])
      authorities.each do |auth|
        url = @browse_url + (AUTHORITY_QUERY_STRING % [@api_key, auth])
        refresh_outcomes_for_authority(url, auth)
      end
    end

    def convert_guids(guids=[])
      guids.each do |guid|
        url = @browse_url + (GUID_QUERY_STRING % [@api_key, guid])
        refresh_outcomes_for_authority(url, guid)
      end
    end

    def refresh_outcomes_for_authority(url, authority)
      res = Canvas::HTTP.get(url)
      if res.code.to_i == 200
        process_json_string(res.body)
      else
        add_warning(I18n.t("academic_benchmark.bad_response_auth", "Couldn't update standards for authority %{auth}.", :auth => authority), "responseCode: #{res.code} - #{res.body}")
      end
    end

    # Get list of all authorities available for this api key and refresh them
    def refresh_all_outcomes
      res = Canvas::HTTP.get(@browse_url + (LIST_AUTHORITIES_QUERY_STRING % @api_key))
      if res.code.to_i == 200
        if data = process_json_string(res.body, true)
          if data["itm"]
            data["itm"].each do |auth_list|
              # This is a country that has a list of authorities
              next unless auth_list["itm"]
              
              auth_list["itm"].each do |auth|
                next unless auth["type"] == "authority"
                url = @browse_url + (GUID_QUERY_STRING % [@api_key, auth["guid"]])
                refresh_outcomes_for_authority(url, auth["title"])
              end
            end
          end
        end
      else
        add_warning(I18n.t("academic_benchmark.bad_response_all", "Couldn't update the standards."), "responseCode: #{res.code} - #{res.body}")
      end
    end

    def process_json_string(json, skip_building=false)
      data = JSON.parse(json, :max_nesting => 50)
      if data["status"] == "ok"
        return data if skip_building
        
        if data = find_authority(data)
          outcomes = Standard.new(data).build_outcomes
          @course[:learning_outcomes] << outcomes
        else
          add_warning(I18n.t("academic_benchmark.no_authority", "Couldn't find an authority to update"))
        end
      else
        if data["ab_err"]
          add_warning(I18n.t("academic_benchmark.failed_request_with_code", "Error accessing Academic Benchmark API"), "responseCode: #{data["ab_err"]["code"]} - #{data["ab_err"]["msg"]}")
        else
          add_warning(I18n.t("academic_benchmark.failed_request", "Error accessing Academic Benchmark API"), "response: #{data.to_json}")
        end
      end
      
      nil
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

  class Standard
    def initialize(data, parent=nil)
      @data = data
      @parent = parent
      @children = []

      return if type == 'course'

      if has_items?
        items.each do |itm|
          Standard.new(itm, self)
        end
      end

      # ignore course types and leaves that don't have a num
      if num || @children.any?
        @parent.add_child(self) if parent
      end
    end

    def build_outcomes
      hash = {:migration_id => guid, :vendor_guid => guid, :low_grade => low_grade, :high_grade => high_grade, :is_global_standard => true}
      hash[:description] = description
      if is_leaf?
        # create outcome
        hash[:type] = 'learning_outcome'
        hash[:title] = build_num_title
        set_default_ratings(hash)
      else
        #create outcome group
        hash[:type] = 'learning_outcome_group'
        hash[:title] = build_title
        hash[:outcomes] = []
        @children.each do |chld|
          hash[:outcomes] << chld.build_outcomes
        end
      end

      hash
    end

    def add_child(itm)
      @children << itm
    end

    def has_items?
      !!(items && items.any?)
    end

    def items
      @data["itm"]
    end

    def guid
      @data["guid"]
    end

    def type
      @data["type"]
    end

    def title
      @data["title"]
    end

    # standards don't have titles so they are built from parent standards/groups
    # it is generated like this:
    # if I have a num, use it and all parent nums on standards
    # if I don't have a num, use my description (potentially truncated at 50)
    def build_num_title
      # when traversing AB data, "standards" will always be deeper in the data
      # hierarchy, so this code will always hit the else before a @parent is nil
      if @parent.is_standard?
        base = @parent.build_num_title
        if base && num
          base + '.' + num
        elsif base
          base
        else
          num
        end
      else
        num
      end
    end

    def build_title
      if num
        build_num_title + " - " + (title || (description && (description[0..TITLE_MAX_LENGTH])))
      else
        title || (description && (description[0..50]))
      end
    end

    def num
      get_meta_field("num")
    end

    def description
      get_meta_field("descr")
    end

    def name
      get_meta_field("name")
    end

    def high_grade
      if @data["meta"] && @data["meta"]["name"]
        @data["meta"]["hi"]
      else
        @parent && @parent.high_grade
      end
    end

    def low_grade
      if @data["meta"] && @data["meta"]["name"]
        @data["meta"]["lo"]
      else
        @parent && @parent.low_grade
      end
    end

    def get_meta_field(field)
      @data["meta"] && @data["meta"][field] && @data["meta"][field]["content"]
    end

    def is_standard?
      type == 'standard'
    end

    # it's only a leaf if it's a standard and has no children, or no children with a 'num'
    # having a num is to ignore extra description nodes that we want to ignore
    def is_leaf?
      num && @children.empty?
    end

    def set_default_ratings(hash)
      hash[:ratings] = [{:description => "Exceeds Expectations", :points => 5},
                        {:description => "Meets Expectations", :points => 3},
                        {:description => "Does Not Meet Expectations", :points => 0}]
      hash[:mastery_points] = 3
      hash[:points_possible] = 3
    end
  end

end
