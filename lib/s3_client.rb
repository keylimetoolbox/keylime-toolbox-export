# frozen_string_literal: true

require "aws-sdk-s3"

# Write data to S3 objects.
class S3Client
  attr_reader :logger

  def initialize(region:, bucket:, logger:)
    @bucket = bucket
    @region = region
    @logger = logger
  end

  def write(key, data, url)
    # TODO: Add Retriable context for ServiceUnavailable and other errors
    s3.put_object(acl: "bucket-owner-full-control", bucket: @bucket, body: data, key: key)
    logger.info("Wrote #{data.size} bytes for #{url} to s3://#{@bucket}/#{key}")
  rescue Aws::S3::Errors::PermanentRedirect
    region = @region || ENV["AWS_REGION"]
    warn "The S3 bucket is not in the #{region} AWS region. Correct this with the --region option."
    exit(-1)
  end

  private

  def s3
    options = {}
    options[:region] = @region if @region
    # TODO: Support --aws-profile option to choose a profile from the configuration file
    # options[:credentials] = Aws::SharedCredentials.new(profile_name: @options.aws_profile) if @options.aws_profile
    @s3 ||= Aws::S3::Client.new(options)
  end
end
