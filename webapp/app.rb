#!/usr/bin/env ruby

require 'sinatra/base'
require 'warden/github'
require 'yaml'

module CodeValet
  class App < Sinatra::Base
    include Warden::GitHub::SSO

    enable  :sessions
    enable  :raise_errors

    set :public_folder, File.dirname(__FILE__) + '/assets'

    use Warden::Manager do |config|
      #config.failure_app = BadAuthentication
      config.default_strategies :github
      config.scope_defaults :default, :config => {
        :scope            => 'read:org,user:email',
        :client_id        => ENV['GITHUB_CLIENT_ID'] || 'a6f2001b9e6c3fabf85c',
        :client_secret    => ENV['GITHUB_CLIENT_SECRET'] || '0672e14addb9f41dec11b5da1219017edfc82a58',
        :redirect_uri => 'http://localhost:9292/github/authenticate',
      }

      config.serialize_from_session { |key| Warden::GitHub::Verifier.load(key) }
      config.serialize_into_session { |user| Warden::GitHub::Verifier.dump(user) }
    end

    get '/' do
      unless env['warden'].user.nil?
        redirect to('http://localhost:8080/securityRealm/commenceLogin?from%F')
      else
        haml :index
      end
    end

    get '/login' do
      env['warden'].authenticate!
      redirect to('/')
    end

    get '/github/authenticate' do
      # If we get to this point and have ?code then we're probably authing
      # for Jenkins and have bounced through the matryoshka doll already
      if params['code']
        redirect to("http://localhost:8080/securityRealm/finishLogin?code=#{params[:code]}")
      else
        redirect '/'
      end
    end

    get '/github/logout' do
      session[:oauthcode] = nil
      env['warden'].logout
      redirect '/'
    end
  end
end
