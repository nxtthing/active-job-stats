require "ostruct"
require "active_job_stats/queue_and_perform_configured_job"

module ActiveJobStats
  module QueueAndPerformState
    extend ActiveSupport::Concern

    QUEUED_STATE = "queued".freeze

    included do
      before_enqueue do |job|
        RedisConnection.with do |conn|
          conn.setex(
            self.class.perform_state_job_key(job),
            self.class.job_stats_expiration_time,
            QUEUED_STATE
          )
        end
      end

      before_perform do |job|
        RedisConnection.with do |conn|
          conn.setex(
            self.class.perform_state_job_key(job),
            self.class.job_stats_expiration_time,
            "performing"
          )
        end
      end

      after_perform do |job|
        RedisConnection.with { |conn| conn.del(self.class.perform_state_job_key(job)) }
      end
    end

    class_methods do
      def set(options = {})
        super.extend(ActiveJobStats::QueueAndPerformConfiguredJob)
      end

      def any_queued_or_performing?(job_key = nil)
        RedisConnection.with do |conn|
          if job_key_in_perform_state_key?
            conn.keys(perform_state_key(combine_perform_state_keys([job_key, "*"]))).any?
          else
            !conn.get(perform_state_key(job_key)).nil?
          end
        end
      end

      def any_queued?(job_key = nil)
        RedisConnection.with do |conn|
          if job_key_in_perform_state_key?
            keys = conn.keys(perform_state_key(combine_perform_state_keys([job_key, "*"])))
            keys.present? && conn.mget(*keys).any? do |status|
              status == QUEUED_STATE
            end
          else
            conn.get(perform_state_key(job_key)) == QUEUED_STATE
          end
        end
      end

      def perform_later_if_uniq(*, **)
        perform_later(*, **) unless any_queued_or_performing?(job_key(*, **))
      end

      def perform_later_if_not_queued(*, **)
        perform_later(*, **) unless any_queued?(job_key(*, **))
      end

      def perform_state_job_key(job)
        key = job_key(*job.arguments)
        key = combine_perform_state_keys([key, job.job_id]) if job_key_in_perform_state_key?
        perform_state_key(key)
      end

      def job_stats_expiration_time
        @job_stats_expiration_time || 20.minutes
      end

      def combine_perform_state_keys(keys)
        keys.compact_blank.join("-")
      end

      def job_key(*, **)
        nil
      end

      def perform_state_key(postfix)
        "active_job_perform_state_#{name}_#{postfix}"
      end

      def job_key_in_perform_state_key?
        true
      end
    end

    def any_queued_or_performing?(job_key = nil)
      k = self.class
      (
        RedisConnection.with { |conn| conn.keys(k.perform_state_key(k.combine_perform_state_keys([job_key, "*"]))) } -
          [k.perform_state_key(job_id)]
      ).any?
    end
  end
end
