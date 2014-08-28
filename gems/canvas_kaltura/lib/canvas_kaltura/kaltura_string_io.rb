module CanvasKaltura
  class KalturaStringIO < StringIO
    attr_accessor :path

    def initialize(string="", file_path=nil)
      super(string)
      self.path = file_path
    end
  end
end