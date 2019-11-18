module ACAEngine::Model
  class Error < Exception
    getter message
  end

  class NoParentError < Error
  end
end
