# frozen_string_literal: true

require "graphql/persisted_queries/store_adapters/redis_client_builder"

module GraphQL
  module PersistedQueries
    module StoreAdapters
      # Redis adapter for storing persisted queries
      class RedisStoreAdapter < BaseStoreAdapter
        def initialize(redis_client:)
          @redis_proc = build_redis_proc(redis_client)
        end

        def fetch_query(hash)
          @redis_proc.call { |redis| redis.get(key_for(hash)) }
        end

        def save_query(hash, query)
          @redis_proc.call { |redis| redis.set(key_for(hash), query, ex: 24 * 60 * 60) }
        end

        private

        def key_for(hash)
          "graphql-persisted-query:#{hash}"
        end

        # rubocop: disable Metrics/MethodLength
        # rubocop: disable Metrics/CyclomaticComplexity
        # rubocop: disable Metrics/PerceivedComplexity
        def build_redis_proc(redis_client)
          if redis_client.is_a?(Hash)
            build_redis_proc(RedisClientBuilder.new(redis_client).build)
          elsif redis_client.is_a?(Proc)
            redis_client
          elsif defined?(::Redis) && redis_client.is_a?(::Redis)
            proc { |&b| b.call(redis_client) }
          elsif defined?(ConnectionPool) && redis_client.is_a?(ConnectionPool)
            proc { |&b| redis_client.with { |r| b.call(r) } }
          else
            raise ArgumentError, ":redis_client accepts Redis, ConnectionPool, Hash or Proc only"
          end
        end
        # rubocop: enable Metrics/MethodLength
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/PerceivedComplexity
      end
    end
  end
end
