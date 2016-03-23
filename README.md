This example will show you how to test and deploy a Ruby worker to IronWorker. The worker in this project pulls data from [Rigor](http://rigor.com) and pushes it into [Datadog](https://www.datadoghq.com/).

**Note**: This asssumes you have an [Iron.io](https://www.iron.io/) account. Also, be sure you've followed the base [getting started instructions on the top level README](https://github.com/iron-io/dockerworker).

### 1. Vendor dependencies (if you update your Gemfile, rerun this):

```sh
docker run --rm -v "$PWD":/worker -w /worker iron/images:ruby-2.1 bundle install --standalone --clean
```

If you have issues during the above build/bundle stage, see [Ruby troubleshooting](https://github.com/iron-io/dockerworker/wiki/Ruby-Troubleshooting).

Then require the vendored gems. Notice in `rigor_datadog.rb`, we add the following so it uses the vendored gems:

```ruby
require_relative 'bundle/bundler/setup'
```

### 2. Test locally

Now it's time to test it locally. First, let's copy the "example" payload and config files and update them to include valid data.

```sh
# copy the sample config, then edit the copy to include your actual credentials
cp example.config.json config.json

# copy the sample payload, then edit the copy to include a real Rigor Check ID
cp example.payload.json payload.json
```

```sh
# run the worker via Docker, passing the payload and config files as environment variables
docker run --rm -it -e "PAYLOAD_FILE=payload.json" -e "CONFIG_FILE=config.json" -v "$PWD":/worker -w /worker iron/images:ruby-2.1 ruby rigor_datadog.rb


# you can also pass custom environment variables directly, if you find that useful
docker run --rm -it -e "PAYLOAD_FILE=payload.json" -e "YOUR_ENV_VAR=ANYTHING" -v "$PWD":/worker -w /worker iron/images:ruby-2.1 ruby rigor_datadog.rb
```

The PAYLOAD_FILE environment variable is passed in to your worker automatically and tells you
where the payload file is. Our [client libraries](http://dev.iron.io/worker/libraries/) help you load the special environment variables automatically.

The YOUR_ENV_VAR environment variable is your custom environment variable. There can
be any number of custom environment variables and they can be anything.

### 3. Package your code

Let's package it up:

```sh
zip -r rigor_datadog.zip .
```

### 4. Upload your code

Then upload it:

```sh
IRON_TOKEN=your_iron_token IRON_PROJECT_ID=your_iron_project_id iron worker upload --name rigor_datadog --zip rigor_datadog.zip iron/images:ruby-2.1 ruby rigor_datadog.rb
```

Note the use of environment variables to specify the Iron project and API token. See [here](http://dev.iron.io/worker/reference/configuration/#quick_start) for more on setting these variables.

### 5. Set config variables in the Iron.io HUD (dashboard)

To mimic your local `config.json` on Iron.io, follow [the instructions for setting config variables via their dashboard](http://dev.iron.io/worker/reference/configuration-variables/#config-via-hud).

### 6. Queue / Schedule jobs for your worker

Now you can start queuing jobs or schedule recurring jobs for your worker:

```sh
iron worker queue --payload-file payload.json --wait rigor_datadog
```

The `--wait` parameter waits for the job to finish, then prints the output.
You will also see a link to [HUD](http://hud.iron.io) where you can see all the rest of the task details along with the log output.

### 7. (optional) Schedule the worker to run periodically

Using Scheduled Tasks, you can run the worker on a schedule to continuously sync Rigor data in Datadog. To schedule your new worker, check out [Iron's scheduling docs](http://dev.iron.io/worker/scheduling/#scheduling_in_dashboard) and set up the Scheduled Task in your Iron.io dashboard.
