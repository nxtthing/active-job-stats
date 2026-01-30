require "ostruct"
require "active_job_stats/queue_and_perform_configured_job"
require "active_job_stats/state_tracker"

module ActiveJobStats
  module QueueAndPerformState
    extend ActiveSupport::Concern

    QUEUED_STATE = "queued".freeze

    included do
      class_attribute :ajs_state_tracker, instance_accessor: false
    end

    class_methods do
      def track_state(args_to_key: -> { nil }, expire_in: 20.minutes, join_concurrent_jobs: false)
        state_tracker = StateTracker.new(
          args_to_key:,
          join_concurrent_jobs:,
          class_name: self.name,
          expire_in_ms: expire_in.to_i
        )

        before_enqueue do |job|
          state_tracker.track_state(job:, state: QUEUED_STATE)
        end

        before_perform do |job|
          state_tracker.track_state(job:, state: "performing")
        end

        after_perform do |job|
          state_tracker.remove_state(job:)
        end

        self.ajs_state_tracker = state_tracker
      end

      def set(options = {})
        super.extend(ActiveJobStats::QueueAndPerformConfiguredJob)
      end

      def perform_later_if_uniq(*, **)
        perform_later(*, **) unless any_queued_or_performing?(*, **)
      end

      def perform_later_if_not_queued(*, **)
        perform_later(*, **) unless any_queued?(*, **)
      end

      def any_queued_or_performing?(*, **)
        self.ajs_state_tracker.any?(*, **)
      end

      def any_queued?(*args, **kwargs)
        self.ajs_state_tracker.any?(*args, states: [QUEUED_STATE], **kwargs)
      end
    end

    def any_queued_or_performing?(*args, **kwargs)
      self.class.ajs_state_tracker.any?(*args, ignore_job_id: job_id, **kwargs)
    end
  end
end
