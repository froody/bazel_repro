```
export AWS_PROFILE=abcd

bazel build //:artifact_1 -s
bazel build //:artifact_2 -s
```
Note that both fail the following error, even though AWS_PROFILE is set and in `--host_action_env`

```
ERROR: Command: 'aws s3 cp --recursive s3://not_a_real_bucket/0/1234567890abcdef/artifacts_1/data/ /tmp/tmp.cqgXwYVsQr/artifact_2.tar.gz/data' failed You may need to run 'aws sso login --profile=' to refresh your AWS S3 credentials

      Name                    Value             Type    Location
      ----                    -----             ----    --------
   profile                <not set>             None    None
access_key                <not set>             None    None
secret_key                <not set>             None    None
    region                <not set>             None    None
```
