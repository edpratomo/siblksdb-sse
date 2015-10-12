Bundler.require
require 'yaml'

class MyApp < Sinatra::Base
  include Sinatra::SSE

  before do
    headers "Access-Control-Allow-Origin" => '*'
  end

  get '/check' do
    "OK"
  end

  get '/seat' do
    # redis = EM::Hiredis.connect
    redis = EM::Hiredis::Client.new
    if request.sse?
      sse_stream do |out|
        out.callback do
          # puts "Stream closed from #{request.ip}"
          redis.pubsub.punsubscribe('*')
          redis.pubsub.close_connection
        end

        redis.pubsub.psubscribe('*') do |channel,msg|
          out.push :data => msg
        end
      end
    else
      stream(:keep_open) do |out|
        out.callback do
          redis.pubsub.punsubscribe('*')
          redis.pubsub.close_connection
        end

        redis.pubsub.psubscribe('*') do |channel,msg|
          out << msg
        end
      end  
    end
  end
end

use Rack::CommonLogger
run MyApp
