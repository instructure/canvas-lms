module Canvas
  module APISerialization
    def stringify!(hash)
      return hash unless stringify_ids?
      Api.stringify_json_ids(hash)
      if (links = hash['links']).present?
        links.each do |key, value|
          links[key] = value.is_a?(Array) ? value.map(&:to_s) : value.to_s
        end
      end
      hash
    end

    def stringify_ids?
      true
    end
  end
end
