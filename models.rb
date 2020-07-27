
require 'sinatra/activerecord'
require 'sqlite3'


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

  validates :seconds,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    }
  
  validates :show_writer,
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
  belongs_to :room
end
