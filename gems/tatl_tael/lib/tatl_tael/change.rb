module TatlTael
  class Change
    attr_reader :path

    attr_reader :status
    private :status

    def initialize(status, path)
      @status = status
      @path   = path
    end

    def added?
      status == "A"
    end

    def deleted?
      status == "D"
    end

    def modified?
      status == "M"
    end
  end
end
