require 'hash_view'
require 'argument_view'
require 'route_view'
require 'return_view'

class MethodView < HashView
  def initialize(method)
    @method = method
  end

  def name
    format(@method.name)
  end

  def api_tag
    @api_tag ||= select_tags("api").first
  end

  def summary
    if api_tag
      format(api_tag.text)
    end
  end

  def nickname
    summary.downcase.
      gsub(/ an? /, ' ').
      gsub(/[^a-z]+/, '_').
      gsub(/^_+|_+$/, '')
  end

  def desc
    format(@method.docstring)
  end

  def raw_arguments
    select_tags("argument")
  end

  def return_tag
    select_tags("returns").first
  end

  def returns
    if return_tag
      ReturnView.new(return_tag.text)
    else
      ReturnViewNull.new
    end
  end

  def controller
    @method.parent.path.underscore.sub("_controller", '')
  end

  def action
    @method.path.sub(/^.*#/, '').sub(/_with_.*$/, '')
  end

  def raw_routes
    ApiRouteSet::V1.api_methods_for_controller_and_action(controller, action)
  end

  def routes
    @routes ||= raw_routes.map do |raw_route|
      RouteView.new(raw_route, self)
    end.select do |route|
      route.api_path !~ /json$/
    end.uniq { |route| route.swagger_path }
  end

  def swagger_type
    returns.to_swagger
  end

  def to_hash
    {
      "name" => name,
      "summary" => summary,
      "desc" => desc,
      "arguments" => arguments.map{ |a| a.to_hash },
      "returns" => returns.to_hash,
      "route" => route.to_hash,
    }
  end

  def unique_nickname_suffix(route)
    if routes.size == 1
      ''
    else
      @nickname_suffix ||= create_nickname_suffix
      if @nickname_suffix[route.swagger_path].length > 0
        "_#{@nickname_suffix[route.swagger_path]}"
      else
        ''
      end
    end
  end

protected
  def select_tags(tag_name)
    @method.tags.select do |tag|
      tag.tag_name.downcase == tag_name
    end
  end

  def create_nickname_suffix
    {}.tap do |nickname_suffix|
      url_list = []
      routes.each do |r|
        url_list << r.swagger_path.split("/")
      end
      calculate_unique_nicknames url_list, 0, [], nickname_suffix
    end
  end

  # Scan through a collection of paths to determine the set of path segments
  # that uniquely identifies each. Every invocation of the method compares a given
  # segment in each path; if they match the method is recursively called to compare
  # the next segment, and if they differ it is called once for each prefix. We assume
  # that there are no identical URLs.
  # Once all calls are complete, the outcome is stored in the @nickname_suffix map,
  # with each URL mapping to its unique nickname.
  #
  # The url_list parameter contains a list of the URLs to be compared, with each URL
  #   formatted as a list of path segments.
  # The idx parameter indicates the segment in each URL to be compared.
  # The prefix parameter contains a list of strings that tracks the path segments that
  #   distinguish the current method invocation.
  # The nickname_suffix contains a cached map of nickname suffixes
  def calculate_unique_nicknames(url_list, idx, prefix, nickname_suffix)
      segments = {}
      # Check the given segment for each URL, and save all possible values in the
      # segments map.
      url_list.each do |url|
        if url.size == idx
          # This URL terminates before the selected segment. Store a null value.
          segments[:none] = [url]
        end
        if url.size > idx
          # Associate this URL with an entry in the segments map.
          segments[url[idx]] = [] unless segments[url[idx]]
          segments[url[idx]] << url
        end
      end

      # Do the recursive call based on whether the current segment matches or
      # differs across all URLs.
      if segments.size == 1
        # There is only one option (ie, the segments match). Call this method on the
        # next segment.
        calculate_unique_nicknames url_list, idx + 1, prefix, nickname_suffix
      end
      if segments.size > 1
        # There are at least two possible values for this segment. Handle each option.
        segments.each do |option, urls|
          # The path option forms part of the unique prefix, so add it to the prefix list.
          p = option == :none ? prefix : prefix + [option.gsub(/\{|\}|\*/i, '')]
          if urls.length == 1
            # If there was only one URL with this value, we've found that URL's unique nickname.
            nickname_suffix[urls.join("/")] = p.join("_")
          else
            # Otherwise recurse on the method with all URLs that have this prefix.
            calculate_unique_nicknames urls, idx + 1, p, nickname_suffix
          end
        end
      end
  end
end
