load("//:download_rules.bzl", "download_s3_uri_as_targz", "download_s3_uri_as_targz2")

download_s3_uri_as_targz(
    name = "artifact_1",
    s3_uri = "s3://not_a_real_bucket/0/1234567890abcdef/artifacts_1/data/",
    dest = "artifact_1.tar.gz",
)

download_s3_uri_as_targz2(
    name = "artifact_2",
    s3_uri = "s3://not_a_real_bucket/0/1234567890abcdef/artifacts_1/data/",
    dest = "artifact_2.tar.gz",
)
