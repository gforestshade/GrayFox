
require 'json'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'jwt'

require './models'

enable :sessions


class FireBaseCredentials
  def initialize(json_path)
    File.open(json_path) do |f|
      @json = JSON.load(f)
    end
    @private_key = OpenSSL::PKey::RSA.new(@json["private_key"])
  end

  @@ins = nil
  def self.ins
    if !@@ins then
      @@ins = FireBaseCredentials.new './credentials/grayfox-6701c-firebase-adminsdk-3deoc-b3cd8d0cd5.json'
    end
    @@ins
  end

  def service_email
    @json["client_email"]
  end

  def private_key
    @private_key
  end
end


def create_custom_token(uid)
  credentials = FireBaseCredentials.ins
  now_seconds = Time.now.to_i
  payload = {iss: credentials.service_email,
             sub: credentials.service_email,
             aud: "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
             iat: now_seconds,
             exp: now_seconds+(60*60), # Maximum expiration time is one hour
             uid: uid,
             claims: {}
            }
  JWT.encode payload, credentials.private_key, "RS256"
end


get '/auth/firebase' do
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return 403, "please login."
  end
  
  create_custom_token(login_user.name)
end
