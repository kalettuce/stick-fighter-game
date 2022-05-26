#!/usr/bin/env python3

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def find_aggregated(table):
    enemies_killed = 0
    last_ts = 0
    playtime = 0
    sessions = 0
    for index, row in table.iterrows():
        if row['aid'] == 11:
            enemies_killed += 1
        this_ts = row['log_ts']
        ts_diff = this_ts - last_ts
        # only count the ones where gap is less than 600 seconds
        if ts_diff < 300:
            playtime += ts_diff
        else:
            sessions += 1
        last_ts = this_ts
    return playtime, sessions, enemies_killed

summary_output = open('output/summary.txt', 'w')

data = pd.read_csv('data/player_actions_log_output.csv', skipinitialspace=True, usecols=[3,6,9,13,14])
data = data.sort_values(['uid', 'log_ts'], ascending=[True, True])

tables = dict(tuple(data.groupby(['uid'])))

pindex = 0
summary = {}
playtime_data = []
sessions_data = []
killed_data = []
for t_key in tables:
    table = tables[t_key]
    (playtime, sessions, enemy_killed) = find_aggregated(table)
    summary[pindex] = (playtime, sessions, enemy_killed)
    playtime_data.append(playtime)
    sessions_data.append(sessions)
    killed_data.append(enemy_killed)
    pindex += 1

playtime_array = np.array(playtime_data)
sessions_array = np.array(sessions_data)
killed_array = np.array(killed_data)

plt.style.use('ggplot')

# plotting playtime vs. players
plt.hist(playtime_array, cumulative=-1, bins=20)
plt.xlabel('Total playtime (Seconds)', fontsize=10)
plt.ylabel('# of players (cumulative)', fontsize=10)
plt.savefig('output/ptime-players.png')
plt.clf();

# plotting sessions vs. players
unique_vals, frequencies = np.unique(sessions_array, return_counts=True)
plt.bar(unique_vals, frequencies, align='center')
plt.xticks(unique_vals)
plt.xlabel('Sessions played', fontsize=10)
plt.ylabel('# of players', fontsize=10)
plt.savefig('output/sessions-players.png')
plt.clf()

# plotting enemies killed vs. players
plt.hist(killed_array, cumulative=-1, bins=40)
plt.xlabel('Total kills', fontsize=10)
plt.ylabel('# of players', fontsize=10)
plt.savefig('output/kills-players.png')
