
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'bcrypt'
require 'securerandom'

require './models'
require './firebase-auth'
require './permutation-order'



enable :sessions

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
    seconds: 15*60,
    show_writer: false)

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
    seconds: seconds,
    show_writer: params[:show_writer].present?,
    phase: -1
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
  @is_in = !!my_ru
  @is_host = my_ru && my_ru.is_host
  erb :room_lobby
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
    return 403, "Please login."
  end
  
  room = Room.find_by(hash_text: hash)
  if !room then
    return 404, "No such room."
  end
  
  my_ru = room.find_room_user(login_user)
  if !my_ru then
    return 403, "You are not in room."
  end

  rows = room.room_users.joins(:user).select('users.name, room_users.is_host')
  roominfo = {
    name: room.name,
    users: rows.map{|r| r.name },
    my_name: login_user.name,
    host_name: rows.find{|r| r.is_host}.name,
    phase: room.phase,
  }
  if roominfo[:phase] >= 0 then
    roominfo[:current_write_index] = my_ru.index_room
    roominfo[:writes] = room.writes.map{|w| w.hash_text }
  end
  json roominfo
end


get '/rooms/b/:hash' do |hash|
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return 404, "Please login."
  end
  
  room = Room.find_by(hash_text: hash)
  if !room then
    return 403, "No such room."
  end

  ru = room.find_room_user(login_user) 
  if !ru || !ru.is_host then
    return redirect "/rooms/0/#{hash}"
  end

  begin
    ActiveRecord::Base.transaction do
      
      _, order2d = calc_room_order(room.occupied, 200)
      room.phase = 0
      room.orders = Marshal.dump(order2d)
      room.last_update_time = Time.now.to_i
      room.save!
      
      room.room_users.each_with_index do |ru, i|
        ru.index_room = i
        ru.save!

        write = room.writes.create!(
          hash_text: SecureRandom.hex(12),
          index_room: i,
          content: '')
      end
      
    end
  rescue
    return redirect "/rooms/0/#{hash}"
  end
  
  redirect "/writes/#{room.writes[0].hash_text}"
end

get '/writes/:hash' do |hash|
  login_user = User.find_by(name: session[:user])
  if !login_user then
    return 403, "please login."
  end

  room = Write.find_by(hash_text: hash).room
  ru = room.find_room_user(login_user) 
  if !ru then
    return 403, "You are not in room."
  end

  @expire = room.last_update_time + room.seconds * (room.phase + 1)
  @custom_token = create_custom_token(hash)
  @is_host = ru.is_host
  erb :write
end

