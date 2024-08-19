FROM ruby:3.1.4-bookworm AS base
LABEL maintainer="jdwright@ldc.upenn.edu"
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends apt-transport-https netcat-openbsd libpq5
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash -
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends nodejs

# use bun instead of node
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/root/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"

# note that bun isn't used to build node_modules anywhere in this file,
# we just copy in node_modules from the codebase.
# this assumes node_modules was built via the container.

# gems are built before copying the app in, so that changes to the app
# don't trigger gems a rebuild.
# note we build gems the same for dev and production
# does stripping dev and test from production save much?
WORKDIR /ua
COPY Gemfile* /ua/

# when changing the Gemfile, target lock in the compose file
FROM base as lock
RUN bundle install
RUN bundle lock --add-platform x86_64-linux


FROM base as bundledbase
ENV BUNDLE_DEPLOYMENT="1"
ENV BUNDLE_PATH="/usr/local/bundle"
#ENV BUNDLE_WITHOUT="development:test"
RUN bundle install
RUN bundle lock --add-platform x86_64-linux
# from the rails dockerfile
RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
# do some cleanup of the bundle directory
# There's some junk left over from the gem builds, like 100mb of
# .o files, etc.
RUN find "${BUNDLE_PATH}" -name "*.o" -delete \
             -o -name "*.c" -delete \
             -o -name "*.h" -delete \
             -o -name "*.cpp" -delete \
             -o -name "*.hpp" -delete \
             -o -name "*.java" -delete \
             -o -name "*.md" -delete \
             -o -name "*.rdoc" -delete \
             -o -name "*LICENSE*" -delete \
             -o -name "Rakefile" -delete \
             -o -name "Gemfile" -delete \
             -o -name "Makefile" -delete \
             -o -name "CHANGELOG" -delete \
             -o -name "CHANGES" -delete \
             -o -name "COPYING" -delete \
             -o -name ".gitignore" -delete \
             -o -path "*/release_notes/*" -delete \
             -o -name ".rspec" -delete

# from the rails dockerfile
RUN bundle exec bootsnap precompile --gemfile


FROM bundledbase AS dev
COPY . /ua/
# from the rails dockerfile
RUN bundle exec bootsnap precompile app/ lib/
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
#CMD ["sleep", "300"]


# I think the only need for a build stage is for assets:precompile,
# because the rails command connects to a db
FROM dev AS build
ENV RAILS_ENV=container_build
ENV RACK_ENV=container_build
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile


FROM ruby:3.1.4-bookworm as deployable
ENV BUNDLE_DEPLOYMENT="1"
ENV BUNDLE_PATH="/usr/local/bundle"
ENV RAILS_ENV=aws
ENV RACK_ENV=aws
RUN apt-get update && \ 
    apt-get upgrade -yqq && \
    apt-get install -yqq --no-install-recommends libpq5 libsqlite3-0
# why doesn't the rails dockerfile have this one?
RUN apt-get autoclean
# from the rails dockerfile
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/root/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /ua /ua
ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /root/.postgresql/root.crt
WORKDIR /ua
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD bundle exec bin/rails s -b 0.0.0.0 
