# frozen_string_literal: true

require "optionparser"
require "unindent"

# Parse options from the command-line arguments.
class ScriptOptions
  attr_accessor :bucket, :path, :region

  class << self
    def parse(options)
      script_options = new

      opt_parser = OptionParser.new do |opts|
        define_options(opts, script_options)
      end

      opt_parser.parse!(options)

      required_arguments(script_options, options)
      validate_or_exit(script_options)

      script_options
    end

    private

    def define_options(opts, script_options)
      banner(opts)
      path_option(opts, script_options)
      region_option(opts, script_options)
      help_option(opts)
      version_option(opts)
    end

    def required_arguments(script_options, options)
      script_options.bucket = options[0]
    end

    def validate_or_exit(script_options)
      errors = validate_arguments(script_options)
      return if errors.empty?

      puts errors.join("\n")
      puts

      ScriptOptions.parse %w[--help]
      exit(-1)
    end

    def validate_arguments(script_options)
      errors = []
      errors << "You must specify an S3 bucket." if script_options.bucket.nil?
      if script_options.region.nil? && ENV["AWS_REGION"].nil?
        errors << "You must specify an AWS region with the --region option or the AWS_REGION environment variable."
      end
      errors
    end

    def banner(opts)
      opts.banner = <<-BANNER.unindent
        Export Google Search Console data from Keylime Toolbox and write it to an S3 bucket.

            #{$PROGRAM_NAME} [options] target-bucket

        Required argument:
            target-bucket      The S3 bucket to write data to.

        Optional parameters:
      BANNER
    end

    def path_option(opts, script_options)
      opts.on(
          "-p PATH",
          "--path PATH",
          "A path prefix to include in the files within the bucket (e.g. data/keylime-toolbox/)"
      ) do |p|
        script_options.path = p.sub(%r{\A/}, "")
      end
    end

    def region_option(opts, script_options)
      opts.on(
          "-r region REGION",
          "--region REGION",
          "The S3 region where the target bucket is. " \
            "If the AWS_REGION environment variable is set, this overrides that."
      ) do |r|
        script_options.region = r
      end
    end

    def help_option(opts)
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    def version_option(opts)
      opts.on_tail("--version", "Show the version") do
        puts VERSION
        exit
      end
    end
  end
end
