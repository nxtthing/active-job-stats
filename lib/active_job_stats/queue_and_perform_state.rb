require "ostruct"

module ActiveJobStats
  module QueueAndPerformState
    extend ActiveSupport::Concern

    QUEUED_STATE = "queued".freeze

    included do
      after_enqueue do |job|
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
      def any_queued_or_performing?(job_key = nil)
        RedisConnection.with { |conn| conn.keys(perform_state_key(combine_perform_state_keys([job_key, "*"]))) }.any?
      end

      def any_queued?(job_key = nil)
        RedisConnection.with do |conn|
          keys = conn.keys(perform_state_key(combine_perform_state_keys([job_key, "*"])))
          keys.present? && conn.mget(*keys).any? do |status|
            status == QUEUED_STATE
          end
        end
      end

      def perform_later_if_uniq(*params)
        perform_later(*params) unless any_queued_or_performing?(job_key(OpenStruct.new(arguments: ::Array.wrap(params))))
      end

      def perform_later_if_not_queued(*params)
        perform_later(*params) unless any_queued?(job_key(OpenStruct.new(arguments: ::Array.wrap(params))))
      end

      def perform_state_job_key(job)
        perform_state_key(combine_perform_state_keys([job_key(job), job.job_id]))
      end

      def job_stats_expiration_time
        @job_stats_expiration_time || 20.minutes
      end

      def combine_perform_state_keys(keys)
        keys.compact_blank.join("-")
      end

      def job_key(_job)
        nil
      end

      def perform_state_key(postfix)
        "active_job_perform_state_#{name}_#{postfix}"
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
