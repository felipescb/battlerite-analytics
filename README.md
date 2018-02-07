# battlerite-analytics
Having Fun With Battlerite (https://www.battlerite.com)


## Parser
### How To

- `Yarn` / `NPM Install`
- `touch .env`
- `.env << BATTLERITE_AUTH=YOUR_API_KEY`
- Edit `index.js` lines 16 and 17 with your MongoDB data

### Todo
- Database data on `.env`
- Get data from new champions (Alysia, Zander)
- Clean useless code (experiences) and libs being used
- Better work with Battlerite API max requests

## Analysis
A lot of work to do here.

### How To
- Open ./analysis dir on your R Studio (main.R)
- Run all libs (lines 1 to 5)
- Setup your database connection (line 7)
- Run all helper functions (getWinRateAll, gamesPlayed, winRate, ...)
- Run code between comments (#-#) , they are almost finished visualizations.

### Todo
- Separate code into files
- Better visualizations
- Discover Meta


