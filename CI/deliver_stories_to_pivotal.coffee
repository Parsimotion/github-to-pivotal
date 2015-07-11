tracker = require('pivotaltracker')
_ = require("lodash")
exec = require('child_process').exec;

TRACKER_TOKEN = process.argv[2]
TRACKER_PROJECT_ID = process.argv[3]
ENVIRONMENT = process.argv[4]

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true

isDevelopment = "#{ENVIRONMENT}" == "development"
storiesFilter = with_state: if isDevelopment then "finished" else "delivered"

client.project(TRACKER_PROJECT_ID).stories.all storiesFilter, (error, stories) ->
	exec 'git tag | grep staging | tail -n1', (error, staging_deploy_tag, stderr) =>
		_.forEach stories, (story) =>
			console.log "Searching for #{story.id} in local git repo."
			exec "git log --grep #{story.id}", (error, search_result, stderr) =>
				process.stdout.write search_result
				if search_result.length > 0
					console.log "Found #{story.id}, marking as delivered to #{ENVIRONMENT}."
					obj = {labels: story.labels}
					obj.labels.push { name: "#{ENVIRONMENT}" }
					if isDevelopment
						obj.current_state = "delivered"
					client.project(TRACKER_PROJECT_ID).story(story.id).update obj, ->
				else
					console.log "Could not find #{story.id} in git repo."
