# Keylime Toolbox Data Export

Export all your historical Google Search Console data from Keylime Toolbox.

This script will read the Google Search Console queries and URLs (pages) data 
that Keylime Toolbox has collected for you, for all your GSC properties. It will
write a CSV per day, for each property for each type of data, to an S3 bucket.

# Installation

This script uses Ruby; make sure you have version 2.1 or later installed:

```bash
$ ruby -v
ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-darwin15]
```

[Download the code](https://github.com/keylimetoolbox/keylime-toolbox-export/archive/master.zip) 
and extract it to a folder. In terminal window and change directory to that folder.

Before using this script you'll need to set up the dependent gems:
 
```bash
$ gem install bundler
$ bundle install
```

# Configuration

Configure the following environment variables for the Keylime Toolbox API:

- `KEYLIME_TOOLBOX_EMAIL`  The email address of your Keylime Toolbox account.
- `KEYLIME_TOOLBOX_EMAIL`  The API token for your account. Look at the API section in 
[your settings](https://app.keylime.io/settings/profile) for details on setting this up.

To access S3 set up AWS credentials. Credentials may be supplied with the following environment 
variables for by setting values in `~/.aws/credentials` or `~/.aws/config`. See 
[AWS shared credentials](https://aws.amazon.com/blogs/security/a-new-and-standardized-way-to-manage-credentials-in-the-aws-sdks/)
for more details.

- `AWS_ACCESS_KEY_ID`      Your access key for AWS.
- `AWS_SECRET_ACCESS_KEY`  Your secret access key for AWS.

Supply the AWS region of the S3 bucket you are using. This may be done through 
an evironment variable or a command-line option (--region). 

- `AWS_REGION`             The AWS region where the S3 bucket is.


# Usage

Run the script providing the target bucket where you want the data written:

```bash
./export-data.rb target-bucket 
```

There are additional options available to configure the bucket region, the file path, and other
aspects. See the complete list with this command:

```bash
./export-data.rb --help 
```

# Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/keylime-toolbox/keylime-toolbox-export.

Run `rubocop -Da export-data.rb lib/` before submitting to ensure that your code
meets style and organizational requirements.

# Future

- Add aggregate data downloads for reporting groups.
- Add Crawl Errors download for GSC properties.
- Ability to limit to specific groups, properties, or date ranges.

# License

The MIT License. See [LICENSE.txt](LICENSE.txt)
