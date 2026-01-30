module ActiveJobStats
  class StateTracker
    def initialize(args_to_key:, join_concurrent_jobs:, expire_in_ms:, class_name:)
      @args_to_key = args_to_key
      @join_concurrent_jobs = join_concurrent_jobs
      @expire_in_ms = expire_in_ms
      @class_name = class_name
    end

    def track_state(job:, state:)
      RedisConnection.with do |conn|
        conn.setex(perform_state_job_key(job), @expire_in_ms, state)
      end
    end

    def remove_state(job:)
      RedisConnection.with { |conn| conn.del(perform_state_job_key(job)) }
    end

    def any?(*args, ignore_job_id: nil, states: nil, **kwargs)
      RedisConnection.with do |conn|
        args_key = @args_to_key.call(*args, **kwargs)
        keys = if @join_concurrent_jobs
                 [perform_state_key(args_key)]
               else
                 conn.keys(perform_state_key(combine_perform_state_keys([args_key, "*"])))
               end
        if ignore_job_id
          keys = keys.reject { |key| key.end_with?(ignore_job_id) }
        end

        current_states = keys.present? ? conn.mget(*keys) : []

        current_states.any? do |state|
          states.nil? || state.in?(states)
        end
      end
    end

    private

    def perform_state_job_key(job)
      key = @args_to_key.call(*job.arguments)
      key = combine_perform_state_keys([key, job.job_id]) unless @join_concurrent_jobs
      perform_state_key(key)
    end

    def combine_perform_state_keys(keys)
      keys.compact_blank.join("-")
    end

    def perform_state_key(postfix)
      "active_job_perform_state_#{@class_name}_#{postfix}"
    end
  end
end
