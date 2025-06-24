FROM ruby:3.2
WORKDIR /app
COPY . .
ENV BUNDLE_WITH="docker"
RUN bundle install
CMD ["bundle", "exec", "rake", "test"]
