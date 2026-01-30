require "ostruct"

module ActiveJobStats
  module QueueAndPerformConfiguredJob
    def perform_later_if_uniq(*, **)
      perform_later(*, **) unless @job_class.any_queued_or_performing?(*, **)
    end

    def perform_later_if_not_queued(*, **)
      perform_later(*, **) unless @job_class.any_queued?(*, **)
    end
  end
end
