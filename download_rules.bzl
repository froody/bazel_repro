# this bazel file defines the build rules for downloading artifacts (such as
# trained ML models) from a remote location as dependencies for build and
# test targets

def _download_s3_uri_impl(ctx):
    """Downloads all files in an S3 directory to a tarball."""
    output = ctx.actions.declare_file(ctx.attr.dest)
    mode = "TARGZ" if ctx.attr.targz else "FILE"
    ctx.actions.run_shell(
        inputs = [ctx.file.download_sh],
        outputs = [output],
        use_default_shell_env=True,
        command = "echo '%s -> %s'; %s %s %s %s" % (
        ctx.attr.s3_uri,
        output.path,
        ctx.file.download_sh.path,
        mode,
        ctx.attr.s3_uri,
        output.path,
        ),
    )
    return DefaultInfo(files = depset([output]))

_download_s3_uri = rule(
    implementation = _download_s3_uri_impl,
    attrs = {
        "s3_uri": attr.string(),
        "dest": attr.string(),
        "targz": attr.bool(),
        "download_sh": attr.label(
            default = "//:download_from_s3.sh",
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
    },
)


# Rule: download_s3_uri_as_targz
# Description: Downloads all files in an S3 directory to a tarball.
# Inputs:
#   name: A unique name for this rule.
#   s3_uri: The S3 URI to download.
#   dest: The destination tarball.
# Outputs:
#   dest: The destination tarball.
# Example:
#   download_s3_uri_as_targz(
#     name = "download_model",
#     s3_uri = "s3://my-bucket/my-model/data/",
#     dest = "model-data.tar.gz",
#   )
def download_s3_uri_as_targz(name, s3_uri, dest):
    if not dest.endswith(".tar.gz"):
        fail("dest must end with .tar.gz")
    native.genrule(
      name = name,
      outs = [dest],
      cmd = "echo '%s -> %s'; %s %s %s %s" % (
        s3_uri,
        dest,
        "$(location //:download_from_s3.sh)",
        "TARGZ",
        s3_uri,
        dest,
      ),
      srcs = ["//:download_from_s3.sh"],
    )

def download_s3_uri_as_targz2(name, s3_uri, dest):
    if not dest.endswith(".tar.gz"):
        fail("dest must end with .tar.gz")
    _download_s3_uri(
        name = name,
        s3_uri = s3_uri,
        dest = dest,
        targz = True,
        visibility = ["//visibility:public"],
    )

# Rule: download_s3_file
# Description: Downloads a file from S3
# Inputs:
#   name: A unique name for this rule.
#   s3_uri: The S3 URI to download (must be a file path).
#   dest: The destination file.
# Outputs:
#   dest: The destination file.
# Example:
#   download_s3_file(
#     name = "download_model",
#     s3_uri = "s3://my-bucket/my-dir/my_image.png",
#     dest = "my_image.png",
#   )
def download_s3_file(name, s3_uri, dest):
    if s3_uri.endswith("/"):
      fail("s3_uri must not end with /, must be a file path")
    fail("dest must end with .tar.gz")
    _download_s3_uri(
        name = name,
        s3_uri = s3_uri,
        dest = dest,
        targz = False,
        visibility = ["//visibility:public"],
    )
