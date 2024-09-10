require "ostruct"

module ActiveJobStats
  module QueueAndPerformConfiguredJob
    def perform_later_if_uniq(*, **)
      job_key = @job_class.job_key(*, **)
      perform_later(*, **) unless @job_class.any_queued_or_performing?(job_key)
    end

    def perform_later_if_not_queued(*, **)
      job_key = @job_class.job_key(*, **)
      perform_later(*, **) unless @job_class.any_queued?(job_key)
    end
  end
end
