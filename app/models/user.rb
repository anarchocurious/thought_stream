class User < ActiveRecord::Base
  HANDLE_MATCHER = /\A[a-z][a-z0-9]+\z/i
  UNACHORED_HANDLE_MATCHER = /[a-z][a-z0-9]+/i

  devise :database_authenticatable, :registerable, :rememberable, :trackable

  has_many :thoughts, inverse_of: :user, dependent: :destroy

  has_many :mentions_as_mentioned, class_name: 'Mention', foreign_key: :mentioned_id, inverse_of: :mentioned, dependent: :destroy
  has_many :mentioners, through: :mentions_as_mentioned

  has_many :mentions, class_name: 'Thought', through: :mentions_as_mentioned, source: :thought

  has_many :mentions_as_mentioner, through: :thoughts, source: :mentions, dependent: :destroy
  has_many :mentioned_users, through: :mentions_as_mentioned, source: :mentioned

  has_many :follows_as_followed, class_name: 'Follow', foreign_key: :followed_id, inverse_of: :followed, dependent: :destroy
  has_many :followers, through: :follows_as_followed

  has_many :follows_as_follower, class_name: 'Follow', foreign_key: :follower_id, inverse_of: :follower, dependent: :destroy
  has_many :following, through: :follows_as_follower, source: :followed

  has_many :checkins, through: :thoughts, inverse_of: :user, dependent: :destroy
  has_many :locations, through: :checkins

  has_one :_thought, class_name: 'Thought', inverse_of: :user # a hack to shut Rails up about the association number
  has_one :most_recent_checkin, -> { most_recent_for_user }, through: :_thought, source: :checkin, class_name: 'Checkin', inverse_of: :user
  has_one :current_location, through: :most_recent_checkin, source: :location, class_name: 'Location', inverse_of: :users_here_now

  validates :handle, presence: true, uniqueness: true, format: HANDLE_MATCHER

  def related_thoughts
    @related_thoughts ||= Thought.where(
      Thought.arel_table[:id].in(
        Arel.sql(thoughts.select(:id).to_sql)
      ).or(
        Thought.arel_table[:id].in(
          Arel.sql(mentions.select(:id).to_sql)
        )
      )
    ).uniq
  end

  def following?(user)
    following.where(id: user.id).exists?
  end

  def average_time_between_thoughts
    @average_time_between_thoughts ||= thoughts.average_time_between_created_ats
  end
end
