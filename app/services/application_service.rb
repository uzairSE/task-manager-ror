# frozen_string_literal: true

class ApplicationService
  include ServiceResult

  class << self
    def call(*args, **kwargs, &block)
      new(*args, **kwargs).call(&block)
    end
  end

  def call
    raise NotImplementedError, "Subclasses must implement #call"
  end
end
