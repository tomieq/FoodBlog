FROM swift:6.0 as builder
RUN apt-get update -y
RUN apt-get install -y libgd-dev libsqlite3-dev
WORKDIR /app
COPY . .
RUN swift build -c release
# aarch64-unknown-linux-gnu for raspberry pi
# x86_64-unknown-linux-gnu for intel based architectures
RUN mkdir output
RUN cp -R $(swift build --show-bin-path -c release)/* output/
RUN strip -s output/FoodBlog

FROM swift:6.0-slim
RUN apt-get update -y
RUN apt-get install -y libgd-dev libsqlite3-dev
WORKDIR /app
# first copy everything to temp directory
COPY --from=builder /app/output/ ./tmp/
# move resources only(linux bundles) to destination
RUN cp -R ./tmp/*.resources .
# remove tmp
RUN rm -rf ./tmp
# now copy your app

COPY --from=builder /app/output/FoodBlog App
COPY Resources /app/Resources
CMD ["./App"]
