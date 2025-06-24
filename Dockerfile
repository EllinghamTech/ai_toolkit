FROM ruby:3.2
WORKDIR /app
COPY . .
RUN bundle install
# Install AWS SDK only for docker-compose testing
RUN gem install aws-sdk-bedrockruntime
CMD ["bundle", "exec", "rake", "test"]
