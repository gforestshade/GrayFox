
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'sinatra/activerecord'
require 'sqlite3'
require 'bcrypt'

enable :sessions


ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: './db/users.db'
)

class Users < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 20 }
  has_secure_password
end


get '/' do
  'fine.'
end

get '/hello/:name' do |name|
  "Hello, #{name}!"
end

get '/users/all' do
  @users = Users.all
  json @users
end

get '/whoami' do
  login_user = Users.find_by(name: session[:user])
  if login_user then
    "You are #{login_user.name}.<br>"
  else
    "No such user."
  end
end

get '/signup' do
  erb :signup
end

post '/signup' do
  @user = Users.new(name: params[:name])
  @user.password = params[:password]
  
  if @user.save then
    redirect "/whoami"
  else
    "Failed to create user."
  end
end


get '/login' do
  @again = params[:f]
  erb :login
end

post '/login' do
  login_user = Users.find_by(name: params[:name])
  if login_user then
    login_user = login_user.authenticate(params[:password])
  end
  
  if login_user then
    session[:user] = login_user.name
    redirect "/whoami"
  else
    redirect "/login?f=0"
  end
end
