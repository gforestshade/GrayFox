
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'sinatra/activerecord'
require 'sqlite3'
require 'bcrypt'

enable :sessions


ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: './db/db.db'
)

class User < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 20 }
  has_secure_password
end


class Room < ActiveRecord::Base
  validates :name,
    presence: true

  validates :number,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 2,
      less_than_or_equal_to: 10
    }

  validates :seconds,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    }
  
  validates :show_prev_writer,
    inclusion: { in: [true, false] }

  has_many :room_users, dependent: :destroy
end

class RoomUser < ActiveRecord::Base
  belongs_to :room
end

class Write < ActiveRecord::Base
end


get '/' do
  login_user = User.find_by(name: session[:user])
  if login_user then
    redirect "/home"
  else
    erb :top
  end
end

get '/hello/:name' do |name|
  user = User.find_by(name: name)
  "Hello, #{user.name}! Your id is #{user.id}"
end

get '/users/all' do
  @users = User.all
  json @users
end

get '/home' do
  login_user = User.find_by(name: session[:user])
  if login_user then
    "You are #{login_user.name}.<br><a href=\"/rooms/create\">Create Room</a>"
  else
    redirect "/"
  end
end

get '/signup' do
  erb :signup
end

post '/signup' do
  @user = User.new(name: params[:name])
  @user.password = params[:password]
  
  if @user.save then
    redirect "/home"
  else
    redirect "/"
  end
end


get '/login' do
  @again = params[:f]
  erb :login
end

post '/login' do
  login_user = User.find_by(name: params[:name])
  if login_user then
    login_user = login_user.authenticate(params[:password])
  end
  
  if login_user then
    session[:user] = login_user.name
    redirect "/home"
  else
    redirect "/login?f=0"
  end
end



get '/rooms/create' do
  @user = User.find_by(name: session[:user])
  if !@user then
    return "please login."
  end
  
  @room = Room.new(
    name: '',
    number: 4,
    seconds: 15*60,
    show_prev_writer: false)

  erb :rooms_create
end

post '/rooms/create' do
  @user = User.find_by(name: session[:user])
  if !@user then
    return "please login."
  end

  seconds = params[:minutes].to_i * 60 + params[:seconds].to_i
  @room = Room.new(
    name: params[:name],
    number: params[:number],
    seconds: seconds,
    show_prev_writer: params[:show_prev_writer].present?
  )

  if !@room.save then
    erb :rooms_create
  end

  room_user = @room.room_users.create(
    user_id: @user.id,
    index_in_room: 0)

  
  if !room_user then
    erb :rooms_create
  end

  obj = {rooms: Room.all, room_users: RoomUser.all}
  json obj
end

