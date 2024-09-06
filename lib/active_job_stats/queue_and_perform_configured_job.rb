require "ostruct"

module ActiveJobStats
  module QueueAndPerformConfiguredJob
    def perform_later_if_uniq(*params)
      job_key = @job_class.job_key(OpenStruct.new(arguments: ::Array.wrap(params)))
      perform_later(*params) unless @job_class.any_queued_or_performing?(job_key)
    end

    def perform_later_if_not_queued(*params)
      job_key = @job_class.job_key(OpenStruct.new(arguments: ::Array.wrap(params)))
      perform_later(*params) unless @job_class.any_queued?(job_key)
    end
  end
end
