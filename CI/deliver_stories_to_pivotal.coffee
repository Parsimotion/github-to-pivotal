tracker = require('pivotaltracker')
_ = require("lodash")
exec = require('child_process').exec;

# TRACKER_TOKEN = process.argv[0]
# TRACKER_PROJECT_ID = process.argv[1]
# ENVIRONMENT = process.argv[2]

TRACKER_TOKEN = "368271fdb6f98f3a67301591b9df3785"
TRACKER_PROJECT_ID = "799115"
ENVIRONMENT = "Development"

client = new tracker.Client(TRACKER_TOKEN);
client.use_ssl = true

client.project(TRACKER_PROJECT_ID).stories.all {with_state: "finished"}, (error, stories) ->

	exec 'git tag | grep staging | tail -n1', (error, staging_deploy_tag, stderr) =>	
		_.forEach stories, (story) =>
			console.log "Searching for #{story.id} in local git repo."
			exec "git log --grep #{story.id}", (error, search_result, stderr) =>
				process.stdout.write search_result

				if search_result.length > 0
					console.log "Found #{story.id}, marking as delivered to #{ENVIRONMENT}."		
					story.labels = if story.labels then story.labels + "," else ""
					story.labels += "#{ENVIRONMENT}"
					if "#{ENVIRONMENT}" == "Development"
						story.update current_state: "delivered"
					else
						story.update()

				else
					console.log "Could not find #{story.id} in git repo."
