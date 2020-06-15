
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'sinatra/activerecord'
require 'sqlite3'
require 'bcrypt'
require 'securerandom'

enable :sessions


ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: './db/db.db'
)

class User < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 20 }
  has_one :room_user
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
  has_many :writes

  
  def find_room_user(user)
    self.room_users.find{|ru| ru.user.id == user.id}
  end

  def occupied
    self.room_users.count
  end
end

class RoomUser < ActiveRecord::Base
  belongs_to :room
  belongs_to :user
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
  json User.all
end

get '/home' do
  @login_user = User.find_by(name: session[:user])
  if @login_user then
    @rooms = Room.all
    erb :home
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
    session[:user] = @user.name
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
    hash_text: SecureRandom.hex(8),
    name: params[:name],
    number: params[:number],
    seconds: seconds,
    show_prev_writer: params[:show_prev_writer].present?
  )

  if !@room.save then
    return erb :rooms_create
  end

  room_user = @room.room_users.create(
    user_id: @user.id,
    is_host: true)
  
  if !room_user then
    return erb :rooms_create
  end

  redirect '/home'
end

get '/rooms/all' do
  json Room.all
end

get '/rooms/0/:hash' do |hash|
  @login_user = User.find_by(name: session[:user])
  if !@login_user then
    return "Please login."
  end
  
  @room = Room.find_by(hash_text: hash)
  if !@room then
    return "No such room."
  end

  my_ru = @room.find_room_user(@login_user)
  if my_ru then
    erb :room_lobby
  else
    "You are not in room."
  end
end

get '/rooms/0/:hash/join' do |hash|
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return "Please login."
  end
  
  room = Room.find_by(hash_text: hash)
  if !room then
    return "No such room."
  end

  if room.find_room_user(login_user) then
    return redirect "/rooms/0/#{hash}"
  end
  
  occupied = room.occupied
  if occupied >= room.number then
    return "This room is full."
  end
  
  room_user = room.room_users.create(
    user_id: login_user.id,
    is_host: false)
  
  if !room_user then
    return 'failed to join room.'
  end

  redirect "/rooms/0/#{hash}"
end

get '/rooms/0/:hash/leave' do |hash|
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return "Please login."
  end
  
  room = Room.find_by(hash_text: hash)
  if !room then
    return "No such room."
  end

  room_user = room.find_room_user(login_user)
  room_user&.destroy
  
  redirect "/home"
end

get '/rooms/0/:hash/info' do |hash|
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return "Please login."
  end
  
  room = Room.find_by(hash_text: hash)
  if !room then
    return "No such room."
  end
  
  my_ru = room.find_room_user(login_user)
  if !my_ru then
    "You are not in room."
  end

  rows = room.room_users.joins(:user).select('users.name, room_users.is_host')
  roominfo = {
    name: room.name,
    users: rows.map{|r| r.name },
    my_name: login_user.name,
    host_name: rows.find{|r| r.is_host}.name
  }
  json roominfo
end


get '/rooms/b/:hash' do |hash|
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return "Please login."
  end
  
  room = Room.find_by(hash_text: hash)
  if !room then
    return "No such room."
  end

  ru = room.find_room_user(login_user) 
  if !ru || !ru.is_host then
    return redirect "/rooms/0/#{hash}"
  end

  room.room_users.each_with_index do |ru, i|
    ru.index_room = i
    if !ru.save then
      return redirect "/rooms/0/#{hash}"
    end

    if !room.writes.create(index_room: i, content: '') then
      return redirect "/rooms/0/#{hash}"
    end
  end

  json Write.all
end
