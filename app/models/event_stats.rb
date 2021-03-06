class EventStats

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def rated_proposals(include_withdrawn=false)
    q = event.proposals.rated
    q = q.not_withdrawn if include_withdrawn
    q.size
  end

  def total_proposals(include_withdrawn=false)
    q = event.proposals
    q = q.not_withdrawn if include_withdrawn
    q.size
  end

  def user_rated_proposals(user, include_withdrawn=false)
    q = user.ratings.for_event(event)
    q = q.not_withdrawn if include_withdrawn
    q.size
  end

  def user_ratable_proposals(user, include_withdrawn=false)
    q = event.proposals.not_owned_by(user)
    q = q.not_withdrawn if include_withdrawn
    q.size
  end

  def accepted_proposals(track_id='all')
    q = event.proposals.accepted
    q = filter_by_track(q, track_id)
    q.size
  end

  def waitlisted_proposals(track_id='all')
    q = event.proposals.waitlisted
    q = filter_by_track(q, track_id)
    q.size
  end

  def soft_accepted_proposals(track_id='all')
    q = event.proposals.soft_accepted
    q = filter_by_track(q, track_id)
    q.size
  end

  def soft_waitlisted_proposals(track_id='all')
    q = event.proposals.soft_waitlisted
    q = filter_by_track(q, track_id)
    q.size
  end

  def all_accepted_proposals(track_id='all')
    q = event.proposals.where(state: [Proposal::ACCEPTED, Proposal::SOFT_ACCEPTED])
    q = filter_by_track(q, track_id)
    q.size + active_custom_sessions(track_id)
  end

  def all_waitlisted_proposals(track_id='all')
    q = event.proposals.where(state: [Proposal::WAITLISTED, Proposal::SOFT_WAITLISTED])
    q = filter_by_track(q, track_id)
    q.size
  end

  def active_custom_sessions(track_id='all')
    q = event.program_sessions.live.without_proposal
    q = filter_by_track(q, track_id)
    q.size
  end

  def review
    stats = {'Total' => track_review_stats}
    event.tracks.each do |track|
      stats[track.name] = track_review_stats(track.id)
    end
    stats
  end

  def track_review_stats(track_id='all')
    p = event.proposals
    p = filter_by_track(p, track_id) unless track_id == 'all'
    {
      proposals: p.count,
      reviews: p.rated.count,
      public_comments: PublicComment.joins(:proposal).where(proposal: p).count,
      internal_comments: InternalComment.joins(:proposal).where(proposal: p).count
    }
  end

  def program
    stats = {'Total' => track_program_stats}
    stats[Track::NO_TRACK] = track_program_stats('')
    event.tracks.each do |track|
      stats[track.name] = track_program_stats(track.id)
    end
    stats
  end

  def track_program_stats(track_id='all')
    {
      accepted: accepted_proposals(track_id),
      soft_accepted: soft_accepted_proposals(track_id),
      waitlisted: waitlisted_proposals(track_id),
      soft_waitlisted: soft_waitlisted_proposals(track_id)
    }
  end

  def team
    stats = {}

    event.teammates.active.alphabetize.each do |teammate|
      rating_count = teammate.ratings_count(event)
      if rating_count > 0
        stats[teammate.name] = {
          reviews: rating_count,
          public_comments: PublicComment.where(user_id: teammate.user_id).joins(proposal: :event).where(proposals: {event_id: event}).count,
          internal_comments: InternalComment.where(user_id: teammate.user_id).joins(proposal: :event).where(proposals: {event_id: event}).count,
        }
      end
    end
    stats
  end

  private

  def filter_by_track(q, track_id)
    q = q.in_track(track_id) unless track_id == 'all'
    q
  end
end
