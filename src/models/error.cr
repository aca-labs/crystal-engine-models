module PlaceOS::Model
  class Error < Exception
    getter message
  end

  class NoParentError < Error
  end

  class MalformedFilter < Error
    def initialize(filters : Array(String)?)
      super("One or more invalid regexes: #{filters}")
    end
  end
end
