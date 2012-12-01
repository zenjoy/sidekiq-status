module Sidekiq::Status::Storage
  RESERVED_FIELDS=%w(status stop update_time).freeze

  protected

  # Stores multiple values into a job's status hash,
  # sets last update time
  # @param [String] id job id
  # @param [Hash] status_updates updated values
  # @return [String] Redis operation status code
  def store_for_id(jid, messages)
    self.set(jid, messages)
    Sidekiq.redis do |conn|
      answers = conn.multi do
        conn.zadd("statuses", Time.now.to_i, jid)
        conn.zremrangebyscore("statuses", 0, Time.now.to_i - Sidekiq::Status::DEFAULT_EXPIRY)
      end
      answers[0]
    end
  end

  def set(jid, messages)
    Sidekiq.redis do |conn|
      answers = conn.multi do
        conn.hmset "statuses:#{jid}", 'update_time', Time.now.to_i, 'status', messages['status']
        conn.hmset "statuses:#{jid}", 'queue', messages['queue'] if messages['queue']
        conn.hmset "statuses:#{jid}", 'args', messages['args'] if messages['args']
        conn.hmset "statuses:#{jid}", 'class', messages['class'] if messages['class']
        conn.expire "statuses:#{jid}", Sidekiq::Status::DEFAULT_EXPIRY
      end
      answers[0]
    end
  end

  # Gets a single valued from job status hash
  # @param [String] id job id
  # @param [String] Symbol field fetched field name
  # @return [String] Redis operation status code
  def read_field_for_id(jid, field)
    Sidekiq.redis do |conn|
      conn.hmget("statuses:#{jid}", field)[0]
    end
  end

  def read_all_fields_for_id(jid)
    result = {}
    Sidekiq.redis do |conn|
      result = conn.hgetall("statuses:#{jid}")
    end
    result
  end
end