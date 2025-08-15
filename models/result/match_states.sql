MODEL (
	name result.match_states,
	kind VIEW
);

SELECT match_state, COUNT(*) count 
FROM matching.matches_with_state 
GROUP BY match_state
ORDER BY match_state
