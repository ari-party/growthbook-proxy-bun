# Build the GrowthBook Proxy app
FROM imbios/bun-node:1-22-slim
WORKDIR /usr/local/src/app

RUN apt-get update && apt-get -y upgrade \
  apt-get install -y ca-certificates curl unzip && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
# Add Bun to the PATH. Bun's installer places it in ~/.bun/bin, which for root is /root/.bun/bin
ENV PATH="/root/.bun/bin:$PATH"

# Copy over minimum files to install dependencies
COPY package.json ./package.json
COPY yarn.lock ./yarn.lock
COPY packages/apps/proxy/package.json ./packages/apps/proxy/package.json
COPY packages/lib/eval/package.json ./packages/lib/eval/package.json
# Yarn install with dev dependencies
RUN yarn install --frozen-lockfile --ignore-optional

# Build the proxy app and do a clean install with only production dependencies
COPY packages ./packages
RUN \
  yarn build:proxy \
  && rm -rf node_modules \
  && rm -rf packages/apps/proxy/node_modules \
  && rm -rf packages/lib/eval/node_modules \
  && yarn install --frozen-lockfile --production=true --ignore-optional

# Directory with build info (git commit sha, build date)
COPY buildinfo* ./buildinfo

EXPOSE 3300
# Use Bun to start the application
CMD ["bun","start"]
