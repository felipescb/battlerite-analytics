//powered by = https://battlerite.js.org/
require('dotenv').config();

const _ = require('lodash/core');
const bjs = require('battlerite.js');
const client = new bjs.Client(process.env.BATTLERITE_AUTH);
const Battlerite_Dev = require('battlerite-dev')
const api = new Battlerite_Dev({key: process.env.BATTLERITE_AUTH}) 
const fs = require('fs');
const assets = JSON.parse(fs.readFileSync('./assets.json', 'utf8'));
const Repeat = require('repeat');

//DB
const MongoClient = require('mongodb').MongoClient;
const assert = require('assert');
const url = 'mongodb://localhost:27017';
const dbName = 'battlerite';


var RosterInfo = [];
var MatchInfo = [];
MatchInfo['Rosters'] = [];
var Line = {};

const heroList = ['Thorn', 'Ruh Kaan', 'Shifu', 'Raigon', 'Bakko', 'Rook', 'Croak', 'Freya',
				  'Destiny', 'Jade', 'Alysia', 'Ashka', 'Taya', 'Varesh', 'Iva', 'Ezmo', 'Jumong',
				  'Lucie', 'Blossom', 'Pestilus', 'Oldur', 'Poloma', 'Pearl', 'Sirius'];

const statsData = ['abilityUses', 'damageDone', 'damageReceived', 'deaths', 'disablesDone', 'disablesReceived',
					'energyGained', 'energyUsed', 'healingDone', 'healingReceived', 'kills', 'score', 'timeAlive'];

String.prototype.isEmpty = function() {
    return (this.length === 0 || !this.trim());
};

function initializeGenericStats() {
	_.each(heroList, function(h) {
		RosterInfo[h] = [];
		RosterInfo[h]['wins'] = 0;
		RosterInfo[h]['lost'] = 0;
		RosterInfo[h]['played'] = 0;
		
		RosterInfo[h]['stats'] = [];
		_.each(statsData, function(s) {
			RosterInfo[h]['stats'][s] = 0;
		})

	})
}

function resetMatchInfo() {
	MatchInfo = [];
	MatchInfo['Rosters'] = [];
}

function mapUserStats(us) {
	var userMapping = [];
	_.each(us, function(k,v) {
		var map = _.filter(assets.Mappings, function(o) { return o.StackableId == v})
		if(map[0] == null) {
			var toGo = String(k);
		} else {
			var toGo = map[0].DevName;
		}
		if(String(k).isEmpty()) k = 'blablacar';
		userMapping[toGo+String(v)] = k;	
	})
	console.log(userMapping);
}

function saveRostersOnMongo(L) {
	MongoClient.connect(url, function(err, client) {
		assert.equal(null, err);
		if (err) console.log('Erro no Mongo Conn: ' + err);
	  	const db = client.db(dbName);
		const collection = db.collection('match_data');
		collection.insertOne(L).catch(e => console.log('error no mongo: ' + e));
	  	client.close();
	});
	Line = {};
}

function parseWinning(w) {
	var i = 0;
	MatchInfo['Rosters']['winning'] = [];
	_.each(w, function(_w,v) {
		_.each(_w.participants, function(_p, v) {
			MatchInfo['Rosters']['winning'][i] = [];
			MatchInfo['Rosters']['winning'][i]['champion'] = _p.champion.name;
			MatchInfo['Rosters']['winning'][i]['stats'] = _p.stats;
			i++;
		});
	});
}

function parseLossers(l) {
	var i = 0;
	MatchInfo['Rosters']['looser'] = [];
	_.each(l, function(_l,v) {
		_.each(_l.participants, function(_p, v) {
			MatchInfo['Rosters']['looser'][i] = [];
			MatchInfo['Rosters']['looser'][i]['champion'] = _p.champion.name;
			MatchInfo['Rosters']['looser'][i]['stats'] = _p.stats;
			i++;
		});
	});
}

function parseRosters(d, then) {
	var winning = _.filter(d, function(o) { return o.won; });
	var lost = _.filter(d, function(o) { return !o.won; });
	
	parseWinning(winning);
	parseLossers(lost);

	if(then)
		then();
}

function parseRostersUserData(rosters, telemetry, rounds, matchId, matchDate) {
	Line = {};
	_.each(rosters, function(r) {
		var won = r.won;
		_.each(r.participants, function(p) {
			var id = p.player.id;
			console.log(p.champion);
			var player_normalized_champion = p.champion.name;
			var userData = _.filter(telemetry, function(o) { return o.dataObject.accountId == id });
			var dataww = userData[0].dataObject;
			dataww.character = player_normalized_champion;

			Line.champion = dataww.character;
			Line.match_id = matchId;
			Line.match_date = matchDate;
			Line.won = won;
			Line.match_type = dataww.serverType;
			Line.rank = dataww.rankingType;
			Line.league = dataww.league;
			Line.division = dataww.division;
			Line.division_rating = dataww.divisionRating;
			Line.season = dataww.seasonId;
			Line.stats = {};

			Line.stats.damageDone = 0;
			Line.stats.damageReceived = 0;
			Line.stats.healingDone = 0;
			Line.stats.healingReceived = 0;
			Line.stats.disablesDone = 0;
			Line.stats.disablesReceived = 0;
			Line.stats.energyGained = 0;
			Line.stats.energyUsed = 0;
			Line.stats.timeAlive = 0;
			Line.stats.abilityUses = 0;

			_.each(rounds, function(r, i) {
				var playerStats = r.dataObject.playerStats;
				var ctxPlayerStats = _.filter(playerStats, function(o) { return o.userID == id });
				Line.stats.damageDone += parseInt(ctxPlayerStats[0].damageDone) || 0;
				Line.stats.damageReceived += parseInt(ctxPlayerStats[0].damageReceived) || 0;
				Line.stats.healingDone += parseInt(ctxPlayerStats[0].healingDone) || 0;
				Line.stats.healingReceived += parseInt(ctxPlayerStats[0].healingReceived) || 0;
				Line.stats.disablesDone += parseInt(ctxPlayerStats[0].disablesDone) || 0;
				Line.stats.disablesReceived += parseInt(ctxPlayerStats[0].disablesReceived) || 0;
				Line.stats.energyGained += parseInt(ctxPlayerStats[0].energyGained) || 0;
				Line.stats.energyUsed += parseInt(ctxPlayerStats[0].energyUsed) || 0;
				Line.stats.timeAlive += parseInt(ctxPlayerStats[0].timeAlive) || 0;
				Line.stats.abilityUses += parseInt(ctxPlayerStats[0].abilityUses) || 0;

				var isLastElement = i == rounds.length -1;
			    if (isLastElement) saveRostersOnMongo(Line);
			});
		});
	});
}

function routine() {
	client.searchMatches({gameMode: ['ranked', 'casual']}, 5).then(matches => {
	   _.each(matches, function(i, a) {
	   		setTimeout(function () {
	          	// MatchInfo['id'] = i.id;
		   		// MatchInfo['map'] = i.map.name;
		   		// MatchInfo['duration'] = i.duration;
		   		// MatchInfo['patch'] = i.patchVersion;
		   		// MatchInfo['gameMode'] = i.patchVersion;
		   		// parseRosters(i.rosters, saveRostersOnMongo);   

		   		var matchId = i.id;
		   		var matchDate = i.createdAt;
		   		
		   		api.telemetry(i.id, {url: false}).then(telemetry => {
		   			var match_telemetry = _.filter(telemetry, function(o) { return o.type == "Structures.MatchReservedUser" });
		   			var round_data = _.filter(telemetry, function(o) { return o.type == "Structures.RoundFinishedEvent" });
		   			parseRostersUserData(i.rosters, match_telemetry, round_data, matchId, matchDate);
		   		}).catch(e => console.log(e));
		   	}, 1000 * a);
	   });
	}).catch(e => console.log('erro no processo normal: ', e));
}

function sleep(ms){
    return new Promise(resolve=>{
        setTimeout(resolve,ms)
    })
}

async function start() {
	var times = 1;
 	Repeat(routine).every(20, 'sec').start.in(1, 'sec').then(null, null, function() {
 		console.log("Repeat: " + times++);
 	})
}

start();


process.on('unhandledRejection', async error => {
  console.log("Rate Limit");
  await sleep(60000)
});