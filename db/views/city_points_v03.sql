SELECT
  city_id,
  day,
  challenge,

  SUM(cc.in_contest)::integer AS in_contest,
  rank() OVER (PARTITION BY day, challenge ORDER BY SUM(in_contest) DESC) AS rank_in_contest,

  COUNT(*) FILTER (WHERE participated) AS participating_users,
  COUNT(*) FILTER (WHERE participated) >= (VALUES (max_allowed_contributors_in_city())) AS complete,
  (VALUES (max_allowed_contributors_in_city())) - COUNT(*) FILTER (WHERE participated) AS remaining_contributions

FROM city_contributions AS cc
GROUP BY city_id, day, challenge;
