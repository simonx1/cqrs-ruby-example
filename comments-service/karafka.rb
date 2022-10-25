# frozen_string_literal: true

require 'json'
require_relative './config/boot'

# This file is auto-generated during the install process.
# If by any chance you've wanted a setup for Rails app, either run the `karafka:install`
# command again or refer to the install templates available in the source codes

ENV['RACK_ENV'] ||= 'development'
ENV['KARAFKA_ENV'] ||= ENV['RACK_ENV']
Bundler.require(:default, ENV['KARAFKA_ENV'])

# Zeitwerk custom loader for loading the app components before the whole
# Karafka framework configuration
APP_LOADER = Zeitwerk::Loader.new
APP_LOADER.enable_reloading

APP_LOADER.setup
APP_LOADER.eager_load

class PostTopicConsumer < Karafka::BaseConsumer
  def consume
    params_batch.each do |message|
      puts
      puts message.payload

      App['event_handlers.comment_created'].call(message.payload)
    end
  end
end

class JsonDeserializer
  def call(message)
    json = JSON.parse(message.payload, symbolize_names: true)
    sanitize_data(json[:data])
    json
  end

  private

  def sanitize_data(data)
    data.each  { |k,v|
      data[k] = v.is_a?(Hash) ? sanitize_data(data) : (k.to_s =~ /.*_at/ ? Time.parse(v) : v) }
  end
end

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka.seed_brokers = %w[kafka://localhost:9092]
    config.client_id = 'consumer_app'
    config.backend = :inline
    config.batch_fetching = true
  end

  # Comment out this part if you are not using instrumentation and/or you are not
  # interested in logging events for certain environments. Since instrumentation
  # notifications add extra boilerplate, if you want to achieve max performance,
  # listen to only what you really need for given environment.
  Karafka.monitor.subscribe(WaterDrop::Instrumentation::StdoutListener.new)
  Karafka.monitor.subscribe(Karafka::Instrumentation::StdoutListener.new)
  Karafka.monitor.subscribe(Karafka::Instrumentation::ProctitleListener.new)

  # Uncomment that in order to achieve code reload in development mode
  # Be aware, that this might have some side-effects. Please refer to the wiki
  # for more details on benefits and downsides of the code reload in the
  # development mode
  #
  # Karafka.monitor.subscribe(
  #   Karafka::CodeReloader.new(
  #     APP_LOADER
  #   )
  # )

  consumer_groups.draw do
    consumer_group :comment_service_comment_group do
      topic :'post-topic' do
        consumer PostTopicConsumer

        deserializer JsonDeserializer.new
      end
    end
  end
end

Karafka.monitor.subscribe('app.initialized') do
  # Put here all the things you want to do after the Karafka framework
  # initialization
end

KarafkaApp.boot!
