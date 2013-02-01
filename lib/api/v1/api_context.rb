module Api::V1
  class ApiContext
    attr_reader :controller, :path, :user, :session
    attr_accessor :page, :per_page

    def initialize(controller, path, user, session, options = {})
      @controller = controller
      @path = path
      @user = user
      @session = session
      @page = options.fetch(:page, 1)
      @per_page = options[:per_page]
    end

    def paginate(collection)
      Api.paginate(collection, controller, path, pagination_options)
    end

    private
    def pagination_options
      if @per_page
        { :page => @page , :per_page => @per_page}
      else
        { :page => @page }
      end
    end
  end
end
