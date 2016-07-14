class User < ApplicationRecord

  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  before_create :create_activation_digest
  has_secure_password
  has_many :microposts,dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
           foreign_key: "follower_id",
           dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
           foreign_key: "followed_id",
           dependent:   :destroy
  has_many :following, through: :active_relationships,  source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  before_save { self.email=email.downcase }
  validates :name, presence: true, length: {minimum: 3}
  validates :email, presence: true, length: {minimum: 5}
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
        BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token=self.new_token
    update_attribute(:remember_digest, User.digest(self.remember_token))
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  # private
  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end
  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end
  # Returns a user's status feed.

  # Creates and assigns the activation token and digest.
  def create_activation_digest

    self.activation_token = SecureRandom.urlsafe_base64
    self.activation_digest = User.digest(activation_token)
  end

  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end
  #chapter 12
  def feed
    microposts
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Follows a user.
  def follow(other_user)
    active_relationships.create(followed_id: other_user.id)
  end

  # Unfollows a user.
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # Returns true if the current user is following the other user.
  def following?(other_user)
    following.include?(other_user)
  end

end
