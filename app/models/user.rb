class User < ActiveRecord::Base
  self.table_name = "users"
  self.primary_key = "user_id"
  cattr_accessor :current

  belongs_to :person, -> { where voided: 0 },  :foreign_key => :person_id

  def try_to_login
    User.authenticate(self.username,self.password)
  end

  def self.authenticate(login, password)
    u = where(["username =?", login]).first
    u && u.authenticated?(password) ? u : nil
  end

  def authenticated?(plain)
    User.encrypt(plain, salt) == password
  end

  def set_password
    self.salt = User.random_string(10) if !self.salt?
    self.password = User.encrypt(self.password,self.salt)
  end

  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def self.encrypt(password,salt)
    Digest::SHA1.hexdigest(password+salt)
  end

  def update_password(new_password)
    self.password = User.encrypt(new_password, self.salt)
    self.save
  end
  
end
