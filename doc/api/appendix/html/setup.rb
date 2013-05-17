include T('default/appendix/html')

def init
  super
end

def appendix
  controllers = options[:controllers]
  
  if options[:all_resources]
    controllers = options[:resources].flatten.select { |o|
      o.is_a?(YARD::CodeObjects::NamespaceObject)
    }
  end

  return unless controllers && controllers.is_a?(Array)

  @appendixes = controllers.collect { |c|
    c.children.select { |o| :appendix == o.type }
  }.flatten

  super
end