SELECT a_detail, COUNT(a_detail) FROM player_actions_log WHERE cid=4
AND NOT aid=1
GROUP BY a_detail;