# Keylime Toolbox Data Export

Export all your historical Google Search Console data from Keylime Toolbox.

This script reads the Google Search Console queries and URLs (pages) data 
that Keylime Toolbox has collected for you, for all your GSC properties. It will
write a CSV per day, for each property, for each type of data, to an S3 bucket.

# Installation

This script uses Ruby; make sure you have version 2.1 or later installed:

```
$ ruby -v
ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-darwin15]
```

[Download the code](https://github.com/keylimetoolbox/keylime-toolbox-export/archive/master.zip) 
and extract it to a folder. In a terminal window change directory to that folder.

Set up the dependent gems:
 
```bash
gem install bundler
bundle install
```

# Configuration

Configure the following environment variables for the Keylime Toolbox API:

- `KEYLIME_TOOLBOX_EMAIL`  The email address of your Keylime Toolbox account.
- `KEYLIME_TOOLBOX_TOKEN`  The API token for your account. Look at the API section in 
[your settings](https://app.keylime.io/settings/profile) to find or set up your token.

To access S3 set up AWS credentials. Credentials may be supplied with the following environment 
variables for by setting values in `~/.aws/credentials` or `~/.aws/config`. See 
[AWS shared credentials](https://aws.amazon.com/blogs/security/a-new-and-standardized-way-to-manage-credentials-in-the-aws-sdks/)
for more details.

- `AWS_ACCESS_KEY_ID`      Your access key for AWS.
- `AWS_SECRET_ACCESS_KEY`  Your secret access key for AWS.

Supply the AWS region of the S3 bucket you are using. This may be done through 
an evironment variable or a command-line option (`--region`). 

- `AWS_REGION`             The AWS region where the S3 bucket is.


# Usage

Run the script providing the target bucket where you want to store the data:

```bash
./export-data target-bucket
```

There are additional options available to configure the bucket region, the file path, and other
aspects. See the complete list with this command:

```bash
./export-data --help
```

## Docker

You can run this script in a Docker container. There is a `Dockerfile` in the repository
that should work out-of-the box. Build the Docker container image like this:

```bash
docker build -t keylime-toolbox-export .
```

You must set the environment variables described above and specify the bucket when you run 
the script, which you can do with a command like this (presuming you named the image
`keylime-toolbox-export` as above):

```bash
docker run --env-file .env keylime-toolbox-export ./export-data target-bucket
```

See [options for setting enviroment variables](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)
in the Docker documentation.

## Kubernetes

You can run the Docker image as a Kubernetes
[Job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)
in your cluster. This will run the script and terminate the pod when the export job (and
container) completes.

There is a sample manifest in `keylime-toolbox-export-job.yml` that you can use as a
starting point for launching your export job. You will need to:
- Push the image to a registry
- Set the environment variables described above
- Set the target bucket

Push the image to a registry with `docker push`. See the [documentation
on `docker push`](https://docs.docker.com/engine/reference/commandline/push/) for details
about the registry host, names, and tags.

```bash
docker push registry-host:5000/my-company/keylime-toolbox-export
```

Change the `image` line in the manifest based on the name (and tag if desired) you used
when you uploaded the image to your registry.

Modify the manifest to set the environment variables. You might consider using
[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to set the secret tokens
and possibly a
[ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
for the other values.

You will need to change the `command` line in the manifest to set the target bucket and add
any other options.

Once configured you launch the job with a command like this:

```bash
kubectl apply -f keylime-toolbox-export-job.yml
```

# Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/keylime-toolbox/keylime-toolbox-export.

Run `rubocop -Da export_data.rb lib/` before submitting to ensure that your code
meets style and organizational requirements.

# Future

- Add aggregate data downloads for reporting groups.
- Add Crawl Errors download for GSC properties.
- Ability to limit to specific groups, properties, or date ranges.

# License

The MIT License. See [LICENSE.txt](LICENSE.txt)
