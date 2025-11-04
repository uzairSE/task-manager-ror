# frozen_string_literal: true

module ServiceResult
  class Result
    attr_reader :success, :data, :errors

    def initialize(success:, data: nil, errors: [])
      @success = success
      @data = data
      @errors = errors
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  def success_result(data = nil)
    Result.new(success: true, data: data)
  end

  def failure_result(errors = [])
    errors = [ errors ] unless errors.is_a?(Array)
    Result.new(success: false, errors: errors)
  end
end
