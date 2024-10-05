# Build Image
```
docker build -t tomieq/food_blog:1.0 .
```

# Run
## Debug server
```
docker run --rm -p 8084:8080 -v food_volume:/app/volume tomieq/food_blog:1.0
```
## Prod server
```
docker run -d --restart always -p 8084:8080 -v food_volume:/app/volume tomieq/food_blog:1.0
```
