class User < ActiveRecord::Base
  validates :login, :length => {:minimum => 5}
end
user = User.new(:login => "foo")
user.save