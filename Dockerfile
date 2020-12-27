# docker build -t sevaldes/lme-even-fec:1.0.0 .
# docker run -v $PWD:/srv sevaldes/lme-even-fec:1.0.0
FROM ruby:2.6-alpine

RUN apk add build-base

WORKDIR /srv

COPY . .

RUN gem install \
        savon \
        mail \
        dotenv \
        whenever

RUN whenever -f schedule.rb -w

CMD ["crond", "-f"]