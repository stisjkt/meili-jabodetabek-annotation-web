Installation:

clone:
$ GIT_SSL_NO_VERIFY=true git clone <repo_url>

config port:
$ nano web-app/MEILI_Travel_Diary/bin www 

config database:
$ nano web-app/MEILI_Travel_Diary/routes/database.js 

install dependencies:
.../web-app/MEILI_Travel_Diary$ npm install

launch server:
.../web-app/MEILI_Travel_Diary/bin$ pm2 start www